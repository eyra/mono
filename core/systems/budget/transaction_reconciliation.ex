defmodule Systems.Budget.TransactionReconciliation do
  @moduledoc """
  SF-OPP-02 reconciliation for pay-in transactions: re-applies OPP's current
  status to `:pending`/`:failed` transactions whose webhook was lost or failed —
  including rescuing a transaction the expiry worker marked `:failed` while OPP
  actually completed it. Driven daily by `Systems.Payment.ReconciliationWorker`.
  """
  import Ecto.Query

  require Logger

  alias Core.Repo
  alias Systems.Budget
  alias Systems.Payment

  @min_age_minutes 60
  @max_age_days 7

  @doc """
  Reconciles `:pending`/`:failed` transactions in the `[min_age_minutes,
  max_age_days]` window against OPP:

    * OPP "completed" → `Budget.Public.complete_transaction/1` (also rescues a
      transaction expiry marked `:failed`; idempotent on already-`:completed`).
    * OPP "failed" → `Budget.Public.fail_transaction/1` for a still-`:pending`
      row (an already-`:failed` one is left untouched).
    * still in flight → left untouched.

  Returns a `Systems.Payment.ReconciliationSummary` tally.
  """
  def run(opts \\ []) do
    min_age = Keyword.get(opts, :min_age_minutes, @min_age_minutes)
    max_age = Keyword.get(opts, :max_age_days, @max_age_days)

    reconcilable_transactions(min_age, max_age)
    |> Enum.reduce(Payment.ReconciliationSummary.new(), &reconcile_transaction/2)
  end

  defp reconcilable_transactions(min_age_minutes, max_age_days) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    age_cutoff = NaiveDateTime.add(now, -min_age_minutes * 60, :second)
    lookback_cutoff = NaiveDateTime.add(now, -max_age_days * 24 * 60 * 60, :second)

    from(t in Budget.TransactionModel,
      where:
        t.status in [:pending, :failed] and t.inserted_at < ^age_cutoff and
          t.inserted_at > ^lookback_cutoff
    )
    |> Repo.all()
  end

  defp reconcile_transaction(%Budget.TransactionModel{transaction_id: nil, id: id}, summary) do
    Logger.warning("[Budget] reconcile: transaction ##{id} has no provider uid — manual review")
    Payment.ReconciliationSummary.tally(summary, :unresolvable)
  end

  defp reconcile_transaction(%Budget.TransactionModel{transaction_id: uid} = transaction, summary) do
    outcome =
      case Payment.Public.get_transaction(uid) do
        {:ok, %{status: status}} -> apply_reconciled_status(transaction, status)
        {:error, reason} -> log_transaction_error(uid, reason)
      end

    Payment.ReconciliationSummary.tally(summary, outcome)
  end

  defp apply_reconciled_status(%{transaction_id: uid}, "completed") do
    Budget.Public.complete_transaction(uid)
    :resolved_completed
  end

  defp apply_reconciled_status(%{status: :pending, transaction_id: uid}, "failed") do
    Budget.Public.fail_transaction(uid)
    :resolved_failed
  end

  defp apply_reconciled_status(_transaction, "failed"), do: :resolved_failed
  defp apply_reconciled_status(_transaction, _status), do: :still_pending

  defp log_transaction_error(uid, reason) do
    Logger.warning("[Budget] reconcile: get_transaction #{uid} failed: #{inspect(reason)}")
    :errors
  end
end
