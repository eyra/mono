defmodule Next.Systems.Graphite.LeaderboardVisibility do
  @moduledoc """
    Leaderboard visibility values.
  """
  use Mica.Enums.Base, {:leaderboard_visibility, [:public, :private]}
end
