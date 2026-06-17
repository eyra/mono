defmodule Systems.Payment.ReconciliationSummary do
  @moduledoc """
  Tally of a reconciliation run, shared by the per-type reconcilers
  (`Fund.Public.reconcile_pending_payouts/1`, `Budget.Public.reconcile_transactions/1`)
  and aggregated by `Systems.Payment.ReconciliationWorker`.

  Outcomes:
    * `:resolved_completed`  — provider terminal "completed"; local driven to completed.
    * `:resolved_failed`     — provider terminal failure; local driven to failed.
    * `:still_pending`       — provider still in flight; left untouched.
    * `:verified`            — local terminal state confirmed present at the provider.
    * `:missing_at_provider` — local terminal/in-flight state with no provider record — critical, needs manual review.
    * `:unresolvable`        — can't be queried (e.g. no provider uid) — needs manual review.
    * `:errors`              — the provider query itself failed.
    * `:skipped`             — not queried because the provider circuit breaker was open.
  """
  @outcomes [
    :resolved_completed,
    :resolved_failed,
    :still_pending,
    :verified,
    :missing_at_provider,
    :unresolvable,
    :errors,
    :skipped
  ]
  @keys [:scanned | @outcomes]

  def outcomes, do: @outcomes

  def new, do: Map.new(@keys, &{&1, 0})

  def tally(summary, outcome) when outcome in @outcomes do
    summary
    |> Map.update!(:scanned, &(&1 + 1))
    |> Map.update!(outcome, &(&1 + 1))
  end

  def merge(a, b), do: Map.merge(a, b, fn _key, v1, v2 -> v1 + v2 end)
end
