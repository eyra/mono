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

  @min_age_minutes 60
  @max_age_days 7

  def new_state, do: State.new()

  @doc """
  Creation window a provider→local scan considers, as `{oldest, newest}`.

  `oldest` bounds how far back the provider listing reaches. `newest` is a
  min-age guard: an object created moments ago may have a local row committing
  right now, and flagging it would flap.

  Overridable per run via `:min_age_minutes` and `:max_age_days`, matching the
  options the local-first reconcilers take.
  """
  def scan_window(opts) do
    min_age = Keyword.get(opts, :min_age_minutes, @min_age_minutes)
    max_age = Keyword.get(opts, :max_age_days, @max_age_days)
    now = DateTime.utc_now()

    {DateTime.add(now, -max_age * 24 * 60 * 60, :second),
     DateTime.add(now, -min_age * 60, :second)}
  end

  @doc """
  Provider withdrawal lookup guarded by the circuit breaker, throttle and
  back-off. Returns `{result, state}` where `result` is the provider tuple or
  `:circuit_open` when the breaker tripped earlier in the run.
  """
  def get_withdrawal(state, uid), do: guarded(state, fn -> Payment.Public.get_withdrawal(uid) end)

  def get_transaction(state, uid),
    do: guarded(state, fn -> Payment.Public.get_transaction(uid) end)

  @doc """
  Provider-side listings for the provider→local pass, under the same breaker and
  throttle as the per-row lookups. One call covers a whole sweep, so a tripped
  breaker here skips the entire pass rather than a single row.
  """
  def list_recent_withdrawals(state, %DateTime{} = since),
    do: guarded(state, fn -> Payment.Public.list_recent_withdrawals(since) end)

  def list_recent_transfers(state, %DateTime{} = since),
    do: guarded(state, fn -> Payment.Public.list_recent_transfers(since) end)

  def list_recent_transactions(state, %DateTime{} = since),
    do: guarded(state, fn -> Payment.Public.list_recent_transactions(since) end)

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
