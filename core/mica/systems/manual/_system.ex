defmodule Systems.Manual.System do
  use Mica.System

  def routes do
    quote do
      require Systems.Manual.Routes
      Systems.Manual.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Manual.Builder.PublicPage, [:creator]}
      ]
    end
  end

  def signal_handlers, do: [Systems.Manual.Switch]
end
