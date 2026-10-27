defmodule Systems.Home.System do
  use Core.System

  def routes do
    quote do
      require Systems.Home.Routes
      Systems.Home.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Home.Page, [:visitor, :member, :creator]}
      ]
    end
  end

  def signal_handlers, do: [Systems.Home.Switch]
end
