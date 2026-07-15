defmodule Systems.Fund.PayoutReconciliation do
  @moduledoc """
  Reconciliation for participant payouts. Dispatches on `PayoutModel.phase/1`:
  a payout in flight is driven to its terminal state from the provider's
  withdrawal status; a stranded one (funds moved but the withdrawal never
  completed) is healed via `Fund.Public.resume_payout/1`; and only a truly
  unrecoverable one (an unconfirmed transfer with no findable charge) is flagged
  for manual review. Driven by `Systems.Payment.ReconciliationWorker`.
  """
  import Ecto.Query

  require Logger

  alias Core.Repo
  alias Systems.Fund
  alias Systems.Payment
  alias Systems.Payment.ReconciliationState, as: State

  @min_age_minutes 60
  @max_age_days 7

  @doc """
  Reconciles payouts in the `[min_age_minutes, max_age_days]` window, returning
  the updated state.
  """
  def run(opts, %State{} = state) do
    min_age = Keyword.get(opts, :min_age_minutes, @min_age_minutes)
    max_age = Keyword.get(opts, :max_age_days, @max_age_days)

    scan_payouts(min_age, max_age)
    |> Enum.reduce(state, &reconcile_payout/2)
  end

  defp scan_payouts(min_age_minutes, max_age_days) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    age_cutoff = NaiveDateTime.add(now, -min_age_minutes * 60, :second)
    lookback_cutoff = NaiveDateTime.add(now, -max_age_days * 24 * 60 * 60, :second)

    # A :failed payout whose funds moved (:withdrawal_retryable) is still open;
    # one that moved nothing already released its lock and is terminal.
    from(p in Fund.PayoutModel,
      where:
        (p.status in [:pending, :completed] or
           (p.status == :failed and not is_nil(p.funds_committed_at))) and
          p.inserted_at < ^age_cutoff and p.inserted_at > ^lookback_cutoff
    )
    |> Repo.all()
  end

  defp reconcile_payout(%Fund.PayoutModel{} = payout, state) do
    reconcile_phase(Fund.PayoutModel.phase(payout), payout, state)
  end

  defp reconcile_phase(phase, payout, state) when phase in [:awaiting_provider, :completed],
    do: poll_provider(payout, state)

  defp reconcile_phase(phase, payout, state)
       when phase in [:awaiting_withdrawal, :withdrawal_retryable],
       do: heal(payout, state)

  defp reconcile_phase(:awaiting_transfer, %Fund.PayoutModel{id: id, status: status}, state) do
    Logger.error("[Fund] reconcile: payout ##{id} has an unconfirmed transfer — manual review")
    record(state, :unresolvable, id, nil, status, nil, %{reason: "unconfirmed transfer"})
  end

  defp poll_provider(%Fund.PayoutModel{id: id, status: status, provider_uid: uid}, state) do
    case Payment.Public.reconcile_get_withdrawal(state, uid) do
      {{:ok, withdrawal}, state} ->
        apply_status(state, id, uid, status, withdrawal)

      {:not_found, state} ->
        Logger.error("[Fund] reconcile: payout ##{id} (#{status}) missing at provider #{uid}")
        record(state, :missing_at_provider, id, uid, status, nil, %{provider: "not_found"})

      {{:error, reason}, state} ->
        Logger.warning("[Fund] reconcile: get_withdrawal #{uid} failed: #{inspect(reason)}")
        record(state, :errors, id, uid, status, nil, %{error: inspect(reason)})

      {:circuit_open, state} ->
        record(state, :skipped, id, uid, status, nil, %{reason: "circuit_open"})
    end
  end

  # resume_payout makes its own provider calls, which don't pass through the
  # circuit breaker; honour an already-open circuit rather than hammering on.
  defp heal(
         %Fund.PayoutModel{id: id, status: status, provider_uid: uid},
         %State{circuit_open: true} = state
       ),
       do: record(state, :skipped, id, uid, status, nil, %{reason: "circuit_open"})

  defp heal(%Fund.PayoutModel{id: id, status: status, provider_uid: uid} = payout, state) do
    case Fund.Public.resume_payout(payout) do
      {:ok, _} ->
        tally_healed(Repo.get!(Fund.PayoutModel, id), state, id, uid, status)

      {:error, :manual_review} ->
        record(state, :unresolvable, id, uid, status, nil, %{reason: "manual review"})

      {:error, reason} ->
        Logger.warning("[Fund] reconcile: resume payout ##{id} failed: #{inspect(reason)}")
        record(state, :errors, id, uid, status, nil, %{error: inspect(reason)})
    end
  end

  # A heal that issued or retried a withdrawal is now in flight — a later pass
  # drives it to terminal, so it counts as still pending, not yet resolved.
  defp tally_healed(payout, state, id, uid, status) do
    case Fund.PayoutModel.phase(payout) do
      :completed -> record(state, :resolved_completed, id, uid, status, "completed", %{})
      :failed -> record(state, :resolved_failed, id, uid, status, "failed", %{})
      _in_flight -> State.tally(state, :still_pending)
    end
  end

  defp apply_status(state, _id, _uid, :completed, _withdrawal),
    do: State.tally(state, :verified)

  defp apply_status(state, id, uid, local_status, %{raw_status: raw_status} = withdrawal) do
    case resolve(uid, withdrawal) do
      {:ok, :still_pending} ->
        State.tally(state, :still_pending)

      {:ok, outcome} ->
        record(state, outcome, id, uid, local_status, raw_status, %{})

      {:error, reason} ->
        record(state, :errors, id, uid, local_status, raw_status, %{error: inspect(reason)})
    end
  end

  defp resolve(uid, %{status: status} = withdrawal) do
    case Fund.Public.apply_withdrawal_status(uid, withdrawal) do
      {:ok, _} -> {:ok, withdrawal_outcome(status)}
      other -> {:error, other}
    end
  rescue
    error -> {:error, error}
  end

  defp withdrawal_outcome(:completed), do: :resolved_completed
  defp withdrawal_outcome(:failed), do: :resolved_failed
  defp withdrawal_outcome(:pending), do: :still_pending

  defp record(state, outcome, id, uid, local_status, provider_status, details) do
    finding = %{
      subject_type: :payout,
      subject_id: id,
      provider_uid: uid,
      local_status_before: to_string(local_status),
      provider_status: provider_status,
      outcome: outcome,
      details: details
    }

    state
    |> State.tally(outcome)
    |> State.add_finding(finding)
  end
end
