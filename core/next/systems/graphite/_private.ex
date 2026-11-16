defmodule Next.Systems.Graphite.Private do
  use NextWeb, :verified_routes

  alias Next.Systems.{
    Graphite
  }

  def get_preview_url(%Graphite.LeaderboardModel{id: id}) do
    # Self composes this system too: build the path for the running SaaS's endpoint.
    path(Mica.SaaS.endpoint(), ~p"/graphite/leaderboard/#{id}")
  end
end
