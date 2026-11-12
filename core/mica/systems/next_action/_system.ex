defmodule Systems.NextAction.System do
  use Mica.System

  def routes do
    quote do
      require Systems.NextAction.Routes
      Systems.NextAction.Routes.routes()
    end
  end

  def grants do
    [
      {Systems.NextAction.OverviewPage, [:member]}
    ]
  end

  def signal_handlers, do: [Systems.NextAction.Switch]
end
