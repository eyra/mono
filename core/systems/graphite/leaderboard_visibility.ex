defmodule Systems.Graphite.LeaderboardVisibility do
  @moduledoc """
    Leaderboard visibility values.
  """
  use Core.Enums.Base, {:leaderboard_visibility, [:public, :private, :private_with_date]}
end
