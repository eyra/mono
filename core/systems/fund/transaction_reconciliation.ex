defmodule Systems.Fund.TransactionReconciliation do
  @moduledoc """
  Reconciliation for pay-in transactions. Re-applies the provider's current
  status to `:pending`/`:failed` transactions whose webhook was lost (including
  rescuing one the expiry worker marked `:failed` while the provider actually
  completed it), and flags `:completed` transactions the provider has no record
  of — a critical discrepancy. Driven by `Systems.Payment.ReconciliationWorker`;
  provider calls go through `Systems.Payment.Reconciliation`
  (throttle / back-off / circuit breaker) and the shared `ReconciliationState`
  is threaded through and returned.
  """
  import Ecto.Query

  alias Core.Repo
  alias Systems.Fund
  alias Systems.Payment
  alias Systems.Payment.ReconciliationState, as: State

  require Logger

  @min_age_minutes 60
  @max_age_days 7

  @doc """
  Reconciles `:pending`, `:failed` and `:completed` transactions in the
  `[min_age_minutes, max_age_days]` window, returning the updated state.
  """
  def run(opts, %State{} = state) do
    min_age = Keyword.get(opts, :min_age_minutes, @min_age_minutes)
    max_age = Keyword.get(opts, :max_age_days, @max_age_days)

    min_age
    |> scan_transactions(max_age)
    |> Enum.reduce(state, &reconcile_transaction/2)
  end

  defp scan_transactions(min_age_minutes, max_age_days) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    age_cutoff = NaiveDateTime.add(now, -min_age_minutes * 60, :second)
    lookback_cutoff = NaiveDateTime.add(now, -max_age_days * 24 * 60 * 60, :second)

    Repo.all(
      from(t in Fund.TransactionModel,
        where:
          t.status in [:pending, :failed, :completed] and t.inserted_at < ^age_cutoff and
            t.inserted_at > ^lookback_cutoff
      )
    )
  end

  defp reconcile_transaction(
         %Fund.TransactionModel{transaction_id: nil, id: id, status: status},
         state
       ) do
    Logger.error(
      "[Budget] reconcile: transaction ##{id} (#{status}) has no provider uid — manual review"
    )

    record(state, :unresolvable, id, nil, status, nil, %{reason: "no provider uid"})
  end

  defp reconcile_transaction(%Fund.TransactionModel{transaction_id: "free_" <> _}, state) do
    State.tally(state, :verified)
  end

  defp reconcile_transaction(
         %Fund.TransactionModel{transaction_id: uid, id: id, status: status} = transaction,
         state
       ) do
    case Payment.Public.reconcile_get_transaction(state, uid) do
      {{:ok, %{status: provider_status, raw_status: raw_status}}, state} ->
        apply_status(state, transaction, provider_status, raw_status)

      {:not_found, state} ->
        Logger.error(
          "[Budget] reconcile: transaction ##{id} (#{status}) missing at provider #{uid}"
        )

        record(state, :missing_at_provider, id, uid, status, nil, %{provider: "not_found"})

      {{:error, reason}, state} ->
        Logger.warning("[Budget] reconcile: get_transaction #{uid} failed: #{inspect(reason)}")
        record(state, :errors, id, uid, status, nil, %{error: inspect(reason)})

      {:circuit_open, state} ->
        record(state, :skipped, id, uid, status, nil, %{reason: "circuit_open"})
    end
  end

  defp apply_status(
         state,
         %Fund.TransactionModel{status: :completed},
         _provider_status,
         _raw_status
       ),
       do: State.tally(state, :verified)

  defp apply_status(
         state,
         %Fund.TransactionModel{id: id, transaction_id: uid, status: status} = transaction,
         provider_status,
         raw_status
       ) do
    case resolve(transaction, provider_status) do
      {:ok, trivial} when trivial in [:still_pending, :verified] ->
        State.tally(state, trivial)

      {:ok, outcome} ->
        record(state, outcome, id, uid, status, raw_status, %{})

      {:error, reason} ->
        record(state, :errors, id, uid, status, raw_status, %{error: inspect(reason)})
    end
  end

  defp resolve(%{transaction_id: uid}, :completed) do
    case Fund.Public.complete_transaction(uid) do
      {:ok, _} -> {:ok, :resolved_completed}
      other -> {:error, other}
    end
  rescue
    error -> {:error, error}
  end

  defp resolve(%{status: :pending, transaction_id: uid}, :failed) do
    case Fund.Public.fail_transaction(uid) do
      {:ok, _} -> {:ok, :resolved_failed}
      {:error, :already_completed} -> {:ok, :verified}
      other -> {:error, other}
    end
  rescue
    error -> {:error, error}
  end

  defp resolve(%{status: :failed}, :failed), do: {:ok, :verified}
  defp resolve(_transaction, _status), do: {:ok, :still_pending}

  defp record(state, outcome, id, uid, local_status, provider_status, details) do
    finding = %{
      subject_type: :transaction,
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
