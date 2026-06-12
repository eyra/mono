defmodule Systems.Payment.ReconciliationWorker do
  @moduledoc """
  Daily SF-OPP-02 reconciliation sweep. Compares our pay-in (`Budget`) and payout
  (`Fund`) state against OPP and resolves safe discrepancies — a lost or failed
  webhook that left a transaction/payout stuck, or a pay-in the expiry worker
  marked `:failed` while OPP actually completed it.

  This is the consistency backstop behind the synchronous webhook path and the
  fast local pay-in expiry, so it should normally find little to do. Every run
  logs an audit summary of what it scanned and resolved.

  Window and cadence are overridable via job args (`min_age_minutes`,
  `max_age_days`) for manual runs and tests.
  """
  use Oban.Worker,
    queue: :default,
    max_attempts: 1,
    unique: [period: :infinity, states: [:available, :scheduled, :executing, :retryable]]

  require Logger

  alias Systems.Budget
  alias Systems.Fund
  alias Systems.Payment.ReconciliationSummary

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    opts = reconcile_opts(args)

    payouts = Fund.Public.reconcile_pending_payouts(opts)
    transactions = Budget.Public.reconcile_transactions(opts)

    log_audit(payouts, transactions)
    :ok
  end

  def perform(args) do
    opts = reconcile_opts(args)

    payouts = Fund.Public.reconcile_pending_payouts(opts)
    transactions = Budget.Public.reconcile_transactions(opts)

    log_audit(payouts, transactions)
    :ok
  end

  defp log_audit(payouts, transactions) do
    total = ReconciliationSummary.merge(payouts, transactions)

    Logger.info(
      "[Payment.Reconciliation] complete — payouts=#{inspect(payouts)} " <>
        "transactions=#{inspect(transactions)} total=#{inspect(total)}"
    )
  end

  defp reconcile_opts(args) do
    Enum.flat_map([:min_age_minutes, :max_age_days], fn key ->
      case Map.fetch(args, Atom.to_string(key)) do
        {:ok, value} -> [{key, value}]
        :error -> []
      end
    end)
  end
end
