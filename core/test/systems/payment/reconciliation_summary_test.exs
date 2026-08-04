defmodule Systems.Payment.ReconciliationSummaryTest do
  @moduledoc """
  The tally each reconciler builds up and the worker aggregates. Its counters
  land verbatim on `ReconciliationRunModel`, so a miscount here is a
  miscounted reconciliation history.
  """
  use ExUnit.Case, async: true

  alias Systems.Payment.ReconciliationSummary, as: Summary

  describe "new/0" do
    test "starts every outcome at zero" do
      summary = Summary.new()

      for outcome <- Summary.outcomes() do
        assert Map.fetch!(summary, outcome) == 0
      end
    end

    test "starts scanned at zero" do
      assert %{scanned: 0} = Summary.new()
    end

    test "carries no keys beyond scanned and the outcomes" do
      assert Summary.new() |> Map.keys() |> Enum.sort() ==
               [:scanned | Summary.outcomes()] |> Enum.sort()
    end
  end

  describe "outcomes/0" do
    test "lists every outcome a reconciler can report" do
      assert Summary.outcomes() == [
               :resolved_completed,
               :resolved_failed,
               :still_pending,
               :verified,
               :missing_at_provider,
               :unresolvable,
               :errors,
               :skipped
             ]
    end
  end

  describe "tally/2" do
    test "counts the outcome" do
      assert %{missing_at_provider: 1} = Summary.tally(Summary.new(), :missing_at_provider)
    end

    test "counts a scan alongside the outcome" do
      assert %{scanned: 1} = Summary.tally(Summary.new(), :missing_at_provider)
    end

    test "accumulates repeats of the same outcome" do
      summary =
        Summary.new()
        |> Summary.tally(:errors)
        |> Summary.tally(:errors)
        |> Summary.tally(:errors)

      assert %{errors: 3, scanned: 3} = summary
    end

    test "leaves the other outcomes untouched" do
      assert %{verified: 0, skipped: 0} = Summary.tally(Summary.new(), :errors)
    end

    test "crashes on an unknown outcome rather than growing the summary a key" do
      assert_raise FunctionClauseError, fn ->
        Summary.tally(Summary.new(), :bogus)
      end
    end

    test "crashes on :scanned: it is a derived total, not something to tally directly" do
      assert_raise FunctionClauseError, fn ->
        Summary.tally(Summary.new(), :scanned)
      end
    end
  end

  describe "merge/2" do
    test "sums each counter pairwise" do
      a = Summary.new() |> Summary.tally(:verified) |> Summary.tally(:errors)
      b = Summary.new() |> Summary.tally(:verified)

      assert %{verified: 2, errors: 1, scanned: 3} = Summary.merge(a, b)
    end

    test "of two fresh summaries stays all zeros" do
      merged = Summary.merge(Summary.new(), Summary.new())

      assert merged == Summary.new()
    end

    test "keeps a fresh summary as the identity" do
      summary = Summary.new() |> Summary.tally(:unresolvable)

      assert Summary.merge(summary, Summary.new()) == summary
    end

    test "is commutative, so reconciler order does not change the run totals" do
      a = Summary.new() |> Summary.tally(:resolved_completed)
      b = Summary.new() |> Summary.tally(:resolved_failed) |> Summary.tally(:skipped)

      assert Summary.merge(a, b) == Summary.merge(b, a)
    end
  end
end
