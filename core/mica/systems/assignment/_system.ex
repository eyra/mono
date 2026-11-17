defmodule Systems.Assignment.System do
  use Mica.System

  def project_items, do: [Systems.Assignment.ProjectItem]

  def directors, do: %{assignment: Systems.Assignment.Director}

  def routes do
    quote do
      require Systems.Assignment.Routes
      Systems.Assignment.Routes.routes()
    end
  end

  def grants do
    [
      {Systems.Assignment.ContentPage, [:owner]},
      {Systems.Assignment.CrewPage, [:participant, :tester]},
      {Systems.Assignment.LandingPage, [:participant, :tester]}
    ]
  end

  def signal_handlers, do: [Systems.Assignment.Switch]

  def notifiers, do: [Systems.Assignment.Notify]
end
