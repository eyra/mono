defmodule Systems.Payment.ReconciliationStateTest do
  @moduledoc """
  The accumulator threaded through a reconciliation sweep. The part worth
  pinning is the circuit breaker: it decides whether the rest of a sweep still
  talks to the provider at all, and `Reconciliation.guarded/2` skips every
  remaining row once it is open.
  """
  use ExUnit.Case, async: true

  alias Systems.Payment.ReconciliationState, as: State

  # The breaker trips on the 5th consecutive failure (@max_consecutive_failures).
  @trip_threshold 5

  describe "new/0" do
    test "starts with an empty summary" do
      assert %State{summary: summary} = State.new()
      assert summary.scanned == 0
    end

    test "starts with no findings" do
      assert %State{findings: []} = State.new()
    end

    test "starts with a closed circuit" do
      refute State.circuit_open?(State.new())
    end
  end

  describe "tally/2" do
    test "counts the outcome on the carried summary" do
      %State{summary: summary} = State.new() |> State.tally(:verified)

      assert summary.verified == 1
      assert summary.scanned == 1
    end

    test "crashes on an outcome the summary does not know" do
      assert_raise FunctionClauseError, fn ->
        State.tally(State.new(), :bogus)
      end
    end
  end

  describe "add_finding/2" do
    test "collects a finding" do
      assert %State{findings: [:finding]} = State.add_finding(State.new(), :finding)
    end

    test "prepends, so findings come out in reverse order of discovery" do
      state =
        State.new()
        |> State.add_finding(:first)
        |> State.add_finding(:second)

      assert %State{findings: [:second, :first]} = state
    end
  end

  describe "record_failure/1" do
    test "counts a consecutive failure" do
      assert %State{consecutive_failures: 1} = State.record_failure(State.new())
    end

    test "leaves the circuit closed below the trip threshold" do
      state = fail_times(State.new(), @trip_threshold - 1)

      assert %State{consecutive_failures: 4} = state
      refute State.circuit_open?(state)
    end

    test "opens the circuit on the #{@trip_threshold}th consecutive failure" do
      state = fail_times(State.new(), @trip_threshold)

      assert %State{consecutive_failures: 5} = state
      assert State.circuit_open?(state)
    end

    test "keeps the circuit open once tripped" do
      state = fail_times(State.new(), @trip_threshold + 3)

      assert State.circuit_open?(state)
    end
  end

  describe "record_success/1" do
    test "resets the consecutive failure count" do
      state =
        State.new()
        |> fail_times(@trip_threshold - 1)
        |> State.record_success()

      assert %State{consecutive_failures: 0} = state
    end

    test "means intermittent failures never trip the breaker" do
      state =
        Enum.reduce(1..10, State.new(), fn _, state ->
          state |> State.record_failure() |> State.record_success()
        end)

      refute State.circuit_open?(state)
    end

    test "does not re-close an already open circuit: the breaker latches for the run" do
      state =
        State.new()
        |> fail_times(@trip_threshold)
        |> State.record_success()

      assert %State{consecutive_failures: 0} = state
      assert State.circuit_open?(state)
    end
  end

  defp fail_times(state, count),
    do: Enum.reduce(1..count, state, fn _, state -> State.record_failure(state) end)
end
