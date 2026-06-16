defmodule Systems.Payment.ReconciliationState do
  @moduledoc """
  Accumulator threaded through a reconciliation sweep. Carries the running
  `ReconciliationSummary` tally, the list of non-trivial findings to persist,
  and the provider circuit-breaker state (consecutive failures → open).
  """
  alias Systems.Payment.ReconciliationSummary

  @max_consecutive_failures 5

  defstruct summary: nil, findings: [], consecutive_failures: 0, circuit_open: false

  def new, do: %__MODULE__{summary: ReconciliationSummary.new()}

  def tally(%__MODULE__{summary: summary} = state, outcome),
    do: %{state | summary: ReconciliationSummary.tally(summary, outcome)}

  def add_finding(%__MODULE__{findings: findings} = state, finding),
    do: %{state | findings: [finding | findings]}

  def record_success(%__MODULE__{} = state),
    do: %{state | consecutive_failures: 0}

  def record_failure(%__MODULE__{consecutive_failures: failures} = state) do
    failures = failures + 1
    %{state | consecutive_failures: failures, circuit_open: failures >= @max_consecutive_failures}
  end

  def circuit_open?(%__MODULE__{circuit_open: open?}), do: open?
end
