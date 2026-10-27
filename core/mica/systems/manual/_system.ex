defmodule Systems.Manual.System do
  use Core.System

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
end
