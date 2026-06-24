defmodule Systems.Payment.Reconciliation do
  @moduledoc """
  Support for the reconciliation sweep: provider calls wrapped with throttling,
  back-off and a circuit breaker, plus the run/finding persistence lifecycle.

  The per-type reconcilers (`Fund.PayoutReconciliation`,
  `Budget.TransactionReconciliation`) thread a `ReconciliationState` through their
  rows and reach the provider only via `get_withdrawal/2` and `get_transaction/2`
  here, so rate-limit and outage handling lives in one place.
  """
  require Logger

  alias Core.Repo
  alias Systems.Payment
  alias Systems.Rate
  alias Systems.Payment.ReconciliationState, as: State
  alias Systems.Payment.ReconciliationRunModel
  alias Systems.Payment.ReconciliationFindingModel

  @max_retries 2
  @max_throttle_waits 5
  @retryable_statuses [429, 500, 502, 503, 504]

  def new_state, do: State.new()

  @doc """
  Provider withdrawal lookup guarded by the circuit breaker, throttle and
  back-off. Returns `{result, state}` where `result` is the provider tuple or
  `:circuit_open` when the breaker tripped earlier in the run.
  """
  def get_withdrawal(state, uid), do: guarded(state, fn -> Payment.Public.get_withdrawal(uid) end)

  def get_transaction(state, uid),
    do: guarded(state, fn -> Payment.Public.get_transaction(uid) end)

  defp guarded(%State{circuit_open: true} = state, _fun), do: {:circuit_open, state}

  defp guarded(%State{} = state, fun) do
    throttle()

    case classify(with_backoff(fun, @max_retries)) do
      {:ok, _} = ok -> {ok, State.record_success(state)}
      :not_found -> {:not_found, State.record_success(state)}
      {:error, _} = error -> {error, State.record_failure(state)}
    end
  end

  defp classify({:ok, _} = ok), do: ok
  defp classify({:error, %Payment.Error{code: :not_found}}), do: :not_found
  defp classify({:error, %Payment.Error{details: %{status: 404}}}), do: :not_found
  defp classify({:error, _} = error), do: error

  defp with_backoff(fun, retries_left) do
    case fun.() do
      {:error, %Payment.Error{details: %{status: status}}}
      when retries_left > 0 and status in @retryable_statuses ->
        Process.sleep(backoff_ms(@max_retries - retries_left + 1))
        with_backoff(fun, retries_left - 1)

      result ->
        result
    end
  end

  defp throttle(attempts \\ 0) do
    Rate.Public.request_permission(:provider_reconcile, "reconciliation", 1)
    :ok
  rescue
    Rate.Public.RateLimitError ->
      if attempts < @max_throttle_waits do
        Process.sleep(backoff_ms(attempts + 1))
        throttle(attempts + 1)
      else
        :ok
      end
  end

  defp backoff_ms(attempt) do
    base = Application.get_env(:core, :reconciliation, [])[:backoff_ms] || 200
    base * attempt
  end

  @doc """
  Inserts a run row at the start of a sweep.
  """
  def start_run(run_type) when run_type in [:cron, :manual] do
    %ReconciliationRunModel{}
    |> ReconciliationRunModel.changeset(%{run_type: run_type, started_at: now()})
    |> Repo.insert!()
  end

  @doc """
  Persists the accumulated findings and finalizes the run row with its tally.
  """
  def finish_run(%ReconciliationRunModel{id: run_id} = run, %State{
        summary: summary,
        findings: findings
      }) do
    persist_findings(run_id, findings)

    run
    |> ReconciliationRunModel.changeset(Map.put(summary, :finished_at, now()))
    |> Repo.update!()
  end

  defp persist_findings(run_id, findings) do
    Enum.each(findings, fn finding ->
      %ReconciliationFindingModel{}
      |> ReconciliationFindingModel.changeset(Map.put(finding, :reconciliation_run_id, run_id))
      |> Repo.insert!()
    end)
  end

  defp now, do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
end
