defmodule LinkWeb.Study.Public do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view

  alias Link.Studies
  alias Link.SurveyTools
  alias Link.SurveyTools.SurveyToolTask

  data study, :any
  data survey_tool, :any
  data task_available?, :boolean
  data task_completed?, :boolean
  data participant?, :boolean

  defp task_available?({:ok, %SurveyToolTask{status: :pending}}), do: true
  defp task_available?(_), do: false
  defp task_completed?({:ok, %SurveyToolTask{status: :completed}}), do: true
  defp task_completed?(_), do: false

  defp assign_participation_info(socket, survey_tool, user, task_info) do
    socket
    |> assign(
      task_available?: task_available?(task_info),
      task_completed?: task_completed?(task_info),
      participant?: SurveyTools.participant?(survey_tool, user)
    )
  end

  def mount(%{"id" => id}, session, socket) do
    user = get_user(socket, session)
    study = Studies.get_study!(id)
    survey_tool = Studies.list_survey_tools(study) |> List.first()
    task_info = SurveyTools.get_or_create_task(survey_tool, user)

    {:ok,
     socket
     |> assign(
       user: user,
       study: study,
       survey_tool: survey_tool
     )
     |> assign_participation_info(survey_tool, user, task_info)}
  end

  def handle_event(
        "signup",
        _params,
        %{assigns: %{survey_tool: survey_tool, user: user}} = socket
      ) do
    {:ok, _} = SurveyTools.apply_participant(survey_tool, user)
    task_info = SurveyTools.get_or_create_task(survey_tool, user)
    {:noreply, socket |> assign_participation_info(survey_tool, user, task_info)}
  end

  def render(assigns) do
    ~H"""
    <div :if={{@task_available?}}>
      <a href={{@survey_tool.survey_url}}>Ga naar vragenlijst</a>
    </div>
    <div :if={{@task_completed?}}>
      Je werk zit erop
    </div>
    <div :if={{not @participant?}}>
      <button :on-click="signup">Aanmelden</button>
    </div>
    """
  end
end
