defmodule Systems.Payment.ReconciliationWorker do
  @moduledoc """
  Daily reconciliation sweep. Compares our pay-in (`Budget`) and payout
  (`Fund`) state against the payment provider and resolves safe discrepancies — a
  lost or failed webhook that left a transaction/payout stuck, or a pay-in the
  expiry worker marked `:failed` while the provider actually completed it. It
  also flags the critical case the synchronous path can't: local terminal state
  the provider has no record of.

  Two final provider→local passes run the comparison in the opposite direction,
  flagging provider-side payout legs and pay-ins with no local row at all — the
  restore-orphan case, which a local-first scan cannot see. They run last so a
  breaker tripped by their whole-listing calls cannot starve the per-row passes.

  Each run is recorded in `reconciliation_runs` (with per-row
  `reconciliation_findings`) and emits a `[:payment, :reconciliation, :stop]`
  telemetry event so AppSignal tracks discrepancy and resolution counts. Provider
  calls are throttled and protected by a circuit breaker via
  `Systems.Payment.Reconciliation`.

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
  alias Systems.Payment

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}), do: run(reconcile_opts(args))

  @doc """
  Runs a reconciliation pass directly (manual / IEx). `opts` may include
  `:min_age_minutes`, `:max_age_days` and `:run_type`.
  """
  def run(opts \\ []) do
    run_type = Keyword.get(opts, :run_type, :manual)
    started = System.monotonic_time()

    run_record = Payment.Public.start_reconciliation_run(run_type)

    state = Payment.Public.new_reconciliation_state()
    state = Fund.Public.reconcile_pending_payouts(opts, state)
    state = Budget.Public.reconcile_transactions(opts, state)
    state = Fund.Public.reconcile_orphaned_payouts(opts, state)
    state = Budget.Public.reconcile_orphaned_transactions(opts, state)

    Payment.Public.finish_reconciliation_run(run_record, state)

    %{summary: summary} = state
    emit_telemetry(summary, run_type, System.monotonic_time() - started)
    log_audit(summary)
    :ok
  end

  defp emit_telemetry(summary, run_type, duration) do
    measurements = Map.put(summary, :duration, duration)
    :telemetry.execute([:payment, :reconciliation, :stop], measurements, %{run_type: run_type})
  end

  defp log_audit(summary) do
    Logger.info("[Payment.Reconciliation] complete — #{inspect(summary)}")
  end

  defp reconcile_opts(args) do
    [:min_age_minutes, :max_age_days]
    |> Enum.flat_map(fn key ->
      case Map.fetch(args, Atom.to_string(key)) do
        {:ok, value} -> [{key, value}]
        :error -> []
      end
    end)
    |> Keyword.put(:run_type, :cron)
  end
end
