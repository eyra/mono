defmodule Systems.Desktop.System do
  use Core.System

  def routes do
    quote do
      require Systems.Desktop.Routes
      Systems.Desktop.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Desktop.Page, [:creator]}
      ]
    end
  end
end
