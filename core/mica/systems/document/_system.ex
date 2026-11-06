defmodule Systems.Document.System do
  use Mica.System

  def routes do
    quote do
      require Systems.Document.Routes
      Systems.Document.Routes.routes()
    end
  end
end
