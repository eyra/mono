defmodule LinkWeb.SurveyToolTaskController do
  use LinkWeb, :controller

  alias Link.SurveyTools

  entity_loader(
    &Loaders.task_loader!/3,
    parents: [
      &Loaders.study!/3,
      &Loaders.survey_tool!/3
    ]
  )

  def start(
        %{assigns: %{survey_tool_task: survey_tool_task}} = conn,
        _params
      ) do
    case survey_tool_task do
      %{status: :pending} -> render(conn, "start.html")
      nil -> render(conn, "not_available.html")
      _ -> render(conn, "already_completed.html")
    end
  end

  def complete(%{assigns: %{survey_tool_task: survey_tool_task}} = conn, _params) do
    case survey_tool_task do
      %{status: :pending} ->
        SurveyTools.complete_task!(survey_tool_task)
        render(conn, "completed.html")

      nil ->
        render(conn, "not_available.html")

      _ ->
        render(conn, "already_completed.html")
    end
  end
end
