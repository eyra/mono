defmodule Systems.Assignment.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.{
    Assignment,
    Alliance
  }

  @impl true
  def view_model(Alliance.CallbackPage, %Alliance.ToolModel{} = tool, assigns) do
    Assignment.AllianceCallbackPageBuilder.view_model(tool, assigns)
  end

  @impl true
  def view_model(page, %Assignment.Model{} = assignment, assigns) do
    builder(page).view_model(assignment, assigns)
  end

  def builder(Assignment.CrewPage), do: Assignment.CrewPageBuilder
  def builder(Assignment.ContentPage), do: Assignment.ContentPageBuilder
  def builder(Assignment.LandingPage), do: Assignment.LandingPageBuilder
end
