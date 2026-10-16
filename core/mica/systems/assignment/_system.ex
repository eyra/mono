defmodule Systems.Assignment.System do
  use Core.System

  def routes do
    quote do
      require Systems.Assignment.Routes
      Systems.Assignment.Routes.routes()
    end
  end

  def grants do
    quote do
      [
        {Systems.Assignment.ContentPage, [:owner]},
        {Systems.Assignment.CrewPage, [:participant, :tester]},
        {Systems.Assignment.LandingPage, [:participant, :tester]}
      ]
    end
  end
end
