defmodule LinkWeb.SurveyToolTaskController do
  use LinkWeb, :controller

  alias Link.SurveyTools

  entity_loader(
    &LinkWeb.SurveyToolTaskController.task_loader!/3,
    parents: [
      &Loaders.survey_tool!/3,
      &Loaders.study!/3
    ]
  )

  def task_loader!(%{assigns: %{survey_tool: survey_tool}} = conn, _params, _as_parent) do
    user = Pow.Plug.current_user(conn)
    {:survey_tool_task, SurveyTools.get_task(survey_tool, user)}
  end

  def start(%{survey_tool: survey_tool} = conn, _params) do
    # Load the appropriate task
    # - when the user has no task show an error
    # - when the user has already completed the task show a message
    # Show screen with link to external tool

    survey_tool_tasks = SurveyTools.list_survey_tool_tasks(survey_tool)
    render(conn, "index.html", survey_tool_tasks: survey_tool_tasks)
  end

  def complete(%{survey_tool: survey_tool} = conn, _params) do
    # Load the appropriate task
    # - when the user has no task show an error
    # - when the user has already completed the task show a message
    # Flag the task as completed.
    # Show a screen that indicates the task has been completed.
    survey_tool_tasks = SurveyTools.list_survey_tool_tasks()
    render(conn, "index.html", survey_tool_tasks: survey_tool_tasks)
  end
end
