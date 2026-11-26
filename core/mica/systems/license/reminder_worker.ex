defmodule Systems.License.ReminderWorker do
  @moduledoc """
  Scheduled Oban worker that reminds users whose license ends within 14 days
  (`License.Public.remind/1`) and tells users whose license has passed its end
  date (`License.Public.tell_ended/1`). Runs daily (`License.System.oban_crons/0`).
  """
  use Oban.Worker,
    priority: 3,
    max_attempts: 3

  require Logger

  alias Systems.License

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    reminded = License.Public.remind()
    ended = License.Public.tell_ended()

    if reminded + ended > 0 do
      Logger.info(
        "[License.ReminderWorker] Reminded #{reminded} users of a license ending soon, told #{ended} users a license ended"
      )
    end

    :ok
  end
end
