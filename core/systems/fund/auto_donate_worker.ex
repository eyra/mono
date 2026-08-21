defmodule Systems.Fund.AutoDonateWorker do
  @moduledoc """
  Worker responsible for warning participants about dormant reward balances and
  donating the ones left unclaimed afterwards.

  See `Systems.Fund.Dormancy` for why the donation clock runs on the warning
  rather than on the approval date.
  """

  use Oban.Worker,
    max_attempts: 3,
    unique: [period: :infinity, states: [:available, :scheduled, :executing, :retryable]]

  require Logger

  alias Systems.Fund

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    dormant_days = Application.get_env(:core, :auto_donate_timeout, 180)
    grace_days = Application.get_env(:core, :auto_donate_grace, 30)
    now = NaiveDateTime.utc_now()

    warned =
      now
      |> NaiveDateTime.add(-(dormant_days - grace_days), :day)
      |> Fund.Public.remind_dormant_rewards(Date.add(Date.utc_today(), grace_days))

    donated =
      now
      |> NaiveDateTime.add(-grace_days, :day)
      |> Fund.Public.donate_dormant_rewards()

    log_audit(length(warned), Enum.count(donated, &donated?/1), Enum.count(donated, &failed?/1))

    :ok
  end

  defp donated?({:ok, _donation}), do: true
  defp donated?(_), do: false

  defp failed?({:error, _reason}), do: true
  defp failed?(_), do: false

  defp log_audit(0, 0, 0), do: :ok

  defp log_audit(warned, donated, failed) do
    Logger.info(
      "[Fund.AutoDonateWorker] warned #{warned} dormant reward(s), " <>
        "auto-donated #{donated} balance(s), #{failed} failure(s)"
    )
  end
end
