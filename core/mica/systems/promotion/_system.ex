defmodule Systems.Promotion.System do
  use Core.System

  def routes do
    quote do
      require Systems.Promotion.Routes
      Systems.Promotion.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Promotion.LandingPage, [:visitor, :member]}
      ]
    end
  end
end
