defmodule LinkWeb.SurveyToolController do
  use LinkWeb, :controller

  alias Link.SurveyTools
  alias Link.SurveyTools.SurveyTool

  entity_loader(
    &Loaders.survey_tool!/3,
    parents: [
      &Loaders.study!/3
    ]
  )

  def index(conn, _params) do
    survey_tools = SurveyTools.list_survey_tools()
    render(conn, "index.html", survey_tools: survey_tools)
  end

  def new(conn, _params) do
    changeset = SurveyTools.change_survey_tool(%SurveyTool{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(%{assigns: %{study: study}} = conn, %{"survey_tool" => survey_tool_params}) do
    case SurveyTools.create_survey_tool(survey_tool_params, study) do
      {:ok, survey_tool} ->
        conn
        |> put_flash(:info, "Survey tool created successfully.")
        |> redirect(to: Routes.study_survey_tool_path(conn, :show, study, survey_tool))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(%{assigns: %{survey_tool: survey_tool}} = conn, _) do
    render(conn, "show.html", survey_tool: survey_tool)
  end

  def edit(%{assigns: %{survey_tool: survey_tool}} = conn, _) do
    changeset = SurveyTools.change_survey_tool(survey_tool)
    render(conn, "edit.html", survey_tool: survey_tool, changeset: changeset)
  end

  def update(%{assigns: %{study: study, survey_tool: survey_tool}} = conn, %{
        "survey_tool" => survey_tool_params
      }) do
    case SurveyTools.update_survey_tool(survey_tool, survey_tool_params) do
      {:ok, survey_tool} ->
        conn
        |> put_flash(:info, "Survey tool updated successfully.")
        |> redirect(to: Routes.study_survey_tool_path(conn, :show, study, survey_tool))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", survey_tool: survey_tool, changeset: changeset)
    end
  end

  def delete(%{assigns: %{study: study, survey_tool: survey_tool}} = conn, _) do
    {:ok, _survey_tool} = SurveyTools.delete_survey_tool(survey_tool)

    conn
    |> put_flash(:info, "Survey tool deleted successfully.")
    |> redirect(to: Routes.study_survey_tool_path(conn, :index, study))
  end
end
