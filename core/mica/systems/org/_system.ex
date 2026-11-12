defmodule Systems.Org.System do
  use Mica.System

  def routes do
    quote do
      require Systems.Org.Routes
      Systems.Org.Routes.routes()
    end
  end

  def grants do
    [
      {Systems.Org.ContentPage, [:admin]}
    ]
  end

  def signal_handlers, do: [Systems.Org.Switch]
end
