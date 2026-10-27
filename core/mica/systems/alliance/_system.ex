defmodule Systems.Alliance.System do
  use Core.System

  def routes do
    quote do
      require Systems.Alliance.Routes
      Systems.Alliance.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Alliance.CallbackPage, [:owner]}
      ]
    end
  end

  def signal_handlers, do: [Systems.Alliance.Switch]
end
