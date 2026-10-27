defmodule Systems.Graphite.System do
  use Core.System

  def routes do
    quote do
      require Systems.Graphite.Routes
      Systems.Graphite.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Graphite.LeaderboardContentPage, [:owner]},
        {Systems.Graphite.LeaderboardPage, [:owner, :participant, :tester]}
      ]
    end
  end

  def signal_handlers, do: [Systems.Graphite.Switch]
end
