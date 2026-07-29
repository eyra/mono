defmodule Systems.Fund.AutoApproveWorker do
  @moduledoc """
  Worker responsible for automatically approving pending rewards
  after n days
  """

  use Oban.Worker,
    max_attempts: 3,
    unique: [period: :infinity, states: [:available, :scheduled, :executing, :retryable]]

  require Logger

  alias Systems.Fund

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    started = System.monotonic_time()
    approve_timeout = Application.get_env(:core, :auto_approve_timeout, 14)

    results =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-approve_timeout, :day)
      |> Fund.Public.approve_pending_rewards()

    approved = Enum.count(results, &approved_now?/1)
    failed = Enum.count(results, &failed?/1)

    emit_telemetry(approved, failed, System.monotonic_time() - started)
    log_audit(approved, failed)

    :ok
  end

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
