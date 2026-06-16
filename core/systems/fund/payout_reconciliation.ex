defmodule Systems.Fund.PayoutReconciliation do
  @moduledoc """
  Reconciliation for participant payouts. Drives `:pending` payouts to their
  terminal state from the provider's current withdrawal status, and flags
  payouts the provider has no record of — a critical discrepancy: money paid out
  locally with no provider counterpart. Driven by
  `Systems.Payment.ReconciliationWorker`; provider calls go through
  `Systems.Payment.Reconciliation` (throttle / back-off / circuit breaker) and
  the shared `ReconciliationState` is threaded through and returned.
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
  Reconciles `:pending` and `:completed` payouts in the
  `[min_age_minutes, max_age_days]` window, returning the updated state.
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

    from(p in Fund.PayoutModel,
      where:
        p.status in [:pending, :completed] and p.inserted_at < ^age_cutoff and
          p.inserted_at > ^lookback_cutoff
    )
    |> Repo.all()
  end

  defp reconcile_payout(%Fund.PayoutModel{id: id, status: status, provider_uid: nil}, state) do
    Logger.error(
      "[Fund] reconcile: payout ##{id} (#{status}) has no provider_uid — manual review"
    )

    record(state, :unresolvable, id, nil, status, nil, %{reason: "no provider_uid"})
  end

  defp reconcile_payout(%Fund.PayoutModel{id: id, status: status, provider_uid: uid}, state) do
    case Payment.Public.reconcile_get_withdrawal(state, uid) do
      {{:ok, %{status: provider_status}}, state} ->
        apply_status(state, id, uid, status, provider_status)

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

  defp apply_status(state, _id, _uid, :completed, _provider_status),
    do: State.tally(state, :verified)

  defp apply_status(state, id, uid, local_status, provider_status) do
    case resolve(uid, provider_status) do
      {:ok, :still_pending} ->
        State.tally(state, :still_pending)

      {:ok, outcome} ->
        record(state, outcome, id, uid, local_status, provider_status, %{})

      {:error, reason} ->
        record(state, :errors, id, uid, local_status, provider_status, %{error: inspect(reason)})
    end
  end

  defp resolve(uid, provider_status) do
    case Fund.Public.apply_withdrawal_status(uid, provider_status) do
      {:ok, _} -> {:ok, withdrawal_outcome(provider_status)}
      other -> {:error, other}
    end
  rescue
    error -> {:error, error}
  end

  defp withdrawal_outcome("completed"), do: :resolved_completed
  defp withdrawal_outcome(status) when status in ["failed", "disapproved"], do: :resolved_failed
  defp withdrawal_outcome(_status), do: :still_pending

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
