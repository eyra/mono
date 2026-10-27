defmodule Systems.Project.System do
  use Core.System

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
end
