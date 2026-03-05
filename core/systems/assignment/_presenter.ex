defmodule Systems.Assignment.Presenter do
  @moduledoc false
  use Frameworks.Concept.Presenter

  alias Systems.Alliance
  alias Systems.Assignment

  @impl true
  def view_model(Alliance.CallbackPage, %Alliance.ToolModel{} = tool, assigns) do
    Assignment.AllianceCallbackPageBuilder.view_model(tool, assigns)
  end

  @impl true
  def view_model(Assignment.CrewTaskSingleView, %Assignment.Model{} = assignment, assigns) do
    Assignment.CrewTaskSingleViewBuilder.view_model(assignment, assigns)
  end

  @impl true
  def view_model(Assignment.CrewTaskListView, %Assignment.Model{} = assignment, assigns) do
    Assignment.CrewTaskListViewBuilder.view_model(assignment, assigns)
  end

  @impl true
  def view_model(page, %Assignment.Model{} = assignment, assigns) do
    builder(page).view_model(assignment, assigns)
  end
end
