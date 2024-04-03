defmodule Systems.Graphite.LeaderboardEnums do
  def status, do: [:concept, :online, :offline]

  def visibility, do: [:public, :private, :private_with_date]
end
