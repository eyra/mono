defmodule  Systems.Campaign.ExpirationWorker do
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{args: _args}) do
    Systems.Crew.Context.mark_expired()
  end
end
