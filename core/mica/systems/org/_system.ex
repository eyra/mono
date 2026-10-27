defmodule Systems.Org.System do
  use Core.System

  def routes do
    quote do
      require Systems.Org.Routes
      Systems.Org.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Org.ContentPage, [:admin]}
      ]
    end
  end

  def signal_handlers, do: [Systems.Org.Switch]
end
