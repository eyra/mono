defmodule Systems.Assignment.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Frameworks.Utility.Module

  alias Systems.{
    Assignment,
    Alliance
  }

  @impl true
  def view_model(%Alliance.ToolModel{} = tool, Alliance.CallbackPage = page, assigns) do
    builder(page).view_model(tool, assigns)
  end

  @impl true
  def view_model(
        %Assignment.Model{director: director} = assignment,
        Assignment.LandingPage = page,
        assigns
      ) do
    Module.get(director, "Presenter").view_model(assignment, page, assigns)
  end

  @impl true
  def view_model(%Assignment.Model{} = assignment, page, assigns) do
    builder(page).view_model(assignment, assigns)
  end

  def builder(Assignment.CrewPage), do: Assignment.CrewPageBuilder
  def builder(Assignment.ContentPage), do: Assignment.ContentPageBuilder
  def builder(Alliance.CallbackPage), do: Assignment.AllianceCallbackPageBuilder
end
