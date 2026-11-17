defmodule Next.Systems.Graphite.System do
  use Mica.System

  def tools, do: [Next.Systems.Graphite.Tool]

  def project_items, do: [Next.Systems.Graphite.LeaderboardItem]

  def routes do
    quote do
      require Next.Systems.Graphite.Routes
      Next.Systems.Graphite.Routes.routes()
    end
  end

  def grants do
    [
      {Next.Systems.Graphite.LeaderboardContentPage, [:owner]},
      {Next.Systems.Graphite.LeaderboardPage, [:owner, :participant, :tester]}
    ]
  end

  def signal_handlers, do: [Next.Systems.Graphite.Switch]

  def feature_flags, do: [:leaderboard]
end
