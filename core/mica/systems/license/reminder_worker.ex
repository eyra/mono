defmodule Systems.License.ReminderWorker do
  @moduledoc """
  Scheduled Oban worker that reminds users whose license ends within 14 days
  (`License.Public.remind/1`). Runs daily (`License.System.oban_crons/0`).
  """
  use Oban.Worker,
    priority: 3,
    max_attempts: 3

  require Logger

  alias Systems.License

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    reminded = License.Public.remind()

    if reminded > 0 do
      Logger.info("[License.ReminderWorker] Reminded #{reminded} users of a license ending soon")
    end

    :ok
  end
end
