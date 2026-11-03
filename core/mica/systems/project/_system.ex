defmodule Systems.Project.System do
  use Mica.System

  def routes do
    quote do
      require Systems.Project.Routes
      Systems.Project.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Project.NodePage, [:owner]},
        {Systems.Project.OverviewPage, [:admin, :creator]}
      ]
    end
  end

  def signal_handlers, do: [Systems.Project.Switch]

  def feature_flags, do: [:leaderboard, :onyx]
end
