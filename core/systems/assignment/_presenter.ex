defmodule Systems.Assignment.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Frameworks.Utility.Module

  alias Systems.{
    Assignment,
    Alliance
  }

  @impl true
  def view_model(Alliance.CallbackPage = page, %Alliance.ToolModel{} = tool, assigns) do
    builder(page).view_model(tool, assigns)
  end

  @impl true
  def view_model(
        Assignment.LandingPage = page,
        %Assignment.Model{director: director} = assignment,
        assigns
      ) do
    Module.get(director, "Presenter").view_model(page, assignment, assigns)
  end

  @impl true
  def view_model(page, %Assignment.Model{} = assignment, assigns) do
    builder(page).view_model(assignment, assigns)
  end

  def builder(Assignment.CrewPage), do: Assignment.CrewPageBuilder
  def builder(Assignment.ContentPage), do: Assignment.ContentPageBuilder
  def builder(Alliance.CallbackPage), do: Assignment.AllianceCallbackPageBuilder
end
