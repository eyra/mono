defmodule Systems.Payment.ReconciliationSummary do
  @moduledoc """
  Tally of a reconciliation run (SF-OPP-02), shared by the per-type reconcilers
  (`Fund.Public.reconcile_pending_payouts/1`, `Budget.Public.reconcile_transactions/1`)
  and aggregated by `Systems.Payment.ReconciliationWorker`.

  Outcomes:
    * `:resolved_completed` — OPP terminal "completed"; local driven to completed.
    * `:resolved_failed`    — OPP terminal failure; local driven to failed.
    * `:still_pending`      — OPP still in flight; left untouched.
    * `:unresolvable`       — can't be queried (e.g. no provider uid) — needs manual review.
    * `:errors`             — the OPP query itself failed.
  """
  @outcomes [:resolved_completed, :resolved_failed, :still_pending, :unresolvable, :errors]
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
