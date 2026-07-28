defmodule Systems.Fund.AutoApproveWorker do
  @moduledoc """
  Worker responsible for automatically approving pending rewards
  after n days
  """

  @approve_timeout 14

  use Oban.Worker,
    max_attempts: 3,
    unique: [period: :infinity, states: [:available, :scheduled, :executing, :retryable]]

  require Logger

  alias Systems.Fund

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    started = System.monotonic_time()

    results =
      DateTime.utc_now()
      |> DateTime.add(-@approve_timeout, :day)
      |> Fund.Public.approve_pending_rewards()

    approved = Enum.count(results, &approved_now?/1)
    failed = Enum.count(results, &failed?/1)

    emit_telemetry(approved, failed, System.monotonic_time() - started)
    log_audit(approved, failed)

    :ok
  end

  # A completed approval is the Multi result, which carries both :reward and
  # :payment. The already-approved no-op returns a bare `Fund.RewardModel`,
  # which also has a :payment field — so :reward is what tells them apart.
  defp approved_now?({:ok, %{reward: _, payment: _}}), do: true
  defp approved_now?(_), do: false

  defp failed?({:error, _}), do: true
  defp failed?(_), do: false

  defp emit_telemetry(approved, failed, duration) do
    :telemetry.execute(
      [:fund, :auto_approve, :stop],
      %{count: approved, failed: failed, duration: duration},
      %{}
    )
  end

  defp log_audit(0, 0), do: :ok

  defp log_audit(approved, failed) do
    Logger.info(
      "[Fund.AutoApproveWorker] auto-approved #{approved} reward(s), #{failed} failure(s)"
    )
  end
end
