defmodule Systems.Graphite.LeaderboardStatus do
  @moduledoc """
    Leaderboard status values.
  """
  use Core.Enums.Base, {:leaderboard_status, [:concept, :online, :offline]}
end
