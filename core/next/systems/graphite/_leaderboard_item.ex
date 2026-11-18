defmodule Next.Systems.Graphite.LeaderboardItem do
  @moduledoc "The `leaderboard` project item type (`Mica.ProjectItem`)."
  use Mica.ProjectItem

  @impl true
  def type, do: "leaderboard"

  @impl true
  def schema, do: Next.Systems.Graphite.LeaderboardModel
end
