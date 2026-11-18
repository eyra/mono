defmodule Systems.Manual.System do
  use Mica.System

  def tools, do: [Systems.Manual.Tool]

  def routes do
    quote do
      require Systems.Manual.Routes
      Systems.Manual.Routes.routes()
    end
  end

  def grants do
    [
      {Systems.Manual.Builder.PublicPage, [:creator]}
    ]
  end

  def signal_handlers, do: [Systems.Manual.Switch]
end
