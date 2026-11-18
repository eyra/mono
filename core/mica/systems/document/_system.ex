defmodule Systems.Document.System do
  use Mica.System

  def tools, do: [Systems.Document.Tool]

  def routes do
    quote do
      require Systems.Document.Routes
      Systems.Document.Routes.routes()
    end
  end
end
