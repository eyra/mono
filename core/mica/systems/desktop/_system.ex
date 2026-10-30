defmodule Systems.Desktop.System do
  use Mica.System

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

  def signal_handlers, do: [Systems.Desktop.Switch]
end
