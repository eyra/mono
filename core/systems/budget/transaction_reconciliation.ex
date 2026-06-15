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
        {:ok, %{status: status}} -> resolve(transaction, status)
        {:error, reason} -> log_failure("get_transaction #{uid}", reason)
      end

    Payment.ReconciliationSummary.tally(summary, outcome)
  end

  # OPP "completed" → complete (also rescues an expiry-failed row, idempotent on :completed).
  defp resolve(%{transaction_id: uid}, "completed") do
    run_resolution(:resolved_completed, "complete_transaction #{uid}", fn ->
      Budget.Public.complete_transaction(uid)
    end)
  end

  # OPP "failed" → fail a still-:pending row; an already-:failed one is left untouched.
  defp resolve(%{status: :pending, transaction_id: uid}, "failed") do
    run_resolution(:resolved_failed, "fail_transaction #{uid}", fn ->
      Budget.Public.fail_transaction(uid)
    end)
  end

  defp resolve(_transaction, "failed"), do: :resolved_failed
  defp resolve(_transaction, _status), do: :still_pending

  # Tally the resolution's success outcome, or :errors if it returns/raises an error —
  # so the audit summary never reports a fix that didn't happen and one bad row can't
  # crash the whole sweep.
  defp run_resolution(success_outcome, label, fun) do
    case fun.() do
      {:ok, _} -> success_outcome
      other -> log_failure(label, other)
    end
  rescue
    error -> log_failure(label, error)
  end

  defp log_failure(label, reason) do
    Logger.warning("[Budget] reconcile: #{label} failed: #{inspect(reason)}")
    :errors
  end
end
