defmodule Systems.Assignment.Presenter do
  use Frameworks.Concept.Presenter

  alias Systems.{
    Assignment,
    Alliance
  }

  @impl true
  def view_model(Alliance.CallbackPage, %Alliance.ToolModel{} = tool, assigns) do
    Assignment.AllianceCallbackPageBuilder.view_model(tool, assigns)
  end

  @impl true
  def view_model(Assignment.CrewTaskSingleView, %Systems.Crew.Model{} = crew, assigns) do
    Assignment.CrewTaskSingleViewBuilder.view_model(crew, assigns)
  end

  @impl true
  def view_model(Assignment.CrewTaskListView, %Systems.Crew.Model{} = crew, assigns) do
    Assignment.CrewTaskListViewBuilder.view_model(crew, assigns)
  end

  @impl true
  def view_model(page, %Assignment.Model{} = assignment, assigns) do
    builder(page).view_model(assignment, assigns)
  end
end
