defmodule Systems.Payment.System do
  use Core.System

  def routes do
    quote do
      require Systems.Payment.Routes
      Systems.Payment.Routes.routes()
    end
  end
end
