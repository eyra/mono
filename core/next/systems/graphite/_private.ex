defmodule Next.Systems.Graphite.Private do
  use MicaWeb, :verified_routes

  alias Next.Systems.{
    Graphite
  }

  def get_preview_url(%Graphite.LeaderboardModel{id: id}) do
    ~p"/graphite/leaderboard/#{id}"
  end
end
