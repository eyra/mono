defmodule Next.Systems.Graphite.System do
  use Mica.System

  def routes do
    quote do
      require Next.Systems.Graphite.Routes
      Next.Systems.Graphite.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Next.Systems.Graphite.LeaderboardContentPage, [:owner]},
        {Next.Systems.Graphite.LeaderboardPage, [:owner, :participant, :tester]}
      ]
    end
  end

  def signal_handlers, do: [Next.Systems.Graphite.Switch]

  def feature_flags, do: [:leaderboard]
end
