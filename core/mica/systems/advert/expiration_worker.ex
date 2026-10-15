defmodule Systems.Advert.ExpirationWorker do
  use Oban.Worker

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: _args}) do
    Logger.warning("Running Towel Feature")
    Systems.Crew.Public.mark_expired()
    Systems.Assignment.Public.rollback_expired_deposits()
  end
end
