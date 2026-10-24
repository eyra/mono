defmodule Systems.Affiliate.System do
  use Core.System

  def routes do
    quote do
      require Systems.Affiliate.Routes
      Systems.Affiliate.Routes.routes()
    end
  end
end
