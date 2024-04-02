defmodule Systems.Graphite.Leaderboard.Status do
  @moduledoc """
  Enum values for the status in `Systems.Graphite.LeaderboardModel`.

  - concept: the leaderboard has been created but is awaiting publication
  - online: the leaderboard can be seen
  - offline: the leaderboard has been taken offline and is no longer visible
  """
  def values, do: [:concept, :online, :offline]
end
