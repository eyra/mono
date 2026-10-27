defmodule Systems.NextAction.System do
  use Core.System

  def routes do
    quote do
      require Systems.NextAction.Routes
      Systems.NextAction.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.NextAction.OverviewPage, [:member]}
      ]
    end
  end

  def signal_handlers, do: [Systems.NextAction.Switch]
end
