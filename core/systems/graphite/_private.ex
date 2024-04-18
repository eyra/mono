defmodule Systems.Graphite.Private do
  use CoreWeb, :verified_routes

  alias Systems.{
    Graphite
  }

  def get_preview_url(%Graphite.LeaderboardModel{id: id}) do
    ~p"/graphite/leaderboard/#{id}/page"
  end
end
