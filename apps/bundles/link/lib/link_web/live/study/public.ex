defmodule LinkWeb.Study.Public do
  @moduledoc """
  The public study screen.
  """
  use LinkWeb, :live_view

  alias EyraUI.Spacing
  alias EyraUI.Hero.HeroSmall
  alias EyraUI.Container.ContentArea
  alias EyraUI.Text.{Title1, Title6, SubHead, BodyLarge, BodyMedium, Bullet}
  alias EyraUI.Button.{PrimaryLiveViewButton, PrimaryButton, SecondaryLiveViewButton}
  alias EyraUI.Case.{Case, True, False}

  alias Link.Studies
  alias Link.Studies.{Study, StudyPublic}
  alias Link.SurveyTools
  alias Link.SurveyTools.SurveyToolTask

  data(study, :any)
  data(survey_tool, :any)
  data(task_available?, :boolean)
  data(task_completed?, :boolean)
  data(participant?, :boolean)
  data(study_public, :any)

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
    survey_tool = load_survey_tool(study)
    task_info = SurveyTools.get_or_create_task(survey_tool, user)
    study_public = StudyPublic.create(study, survey_tool)

    {:ok,
     socket
     |> assign(
       user: user,
       study: study,
       survey_tool: survey_tool,
       study_public: study_public
     )
     |> assign_participation_info(survey_tool, user, task_info)}
  end

  def load_survey_tool(%Study{} = study) do
    case Studies.list_survey_tools(study) do
      [] -> raise "Expected at least one survey tool for study #{study.title}"
      [survey_tool | _] -> survey_tool
    end
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

  def handle_event("withdraw", _params, socket) do
    study_public = socket.assigns[:study_public]
    user = socket.assigns[:user]

    SurveyTools.get_survey_tool!(study_public.survey_tool_id)
    |> SurveyTools.withdraw_participant(user)

    {:noreply, push_redirect(socket, to: Routes.live_path(socket, LinkWeb.Dashboard))}
  end

  def render(assigns) do
    ~H"""
      <HeroSmall title={{ dgettext("eyra-study", "study.public.title") }} />
      <ContentArea>
        <SubHead>{{ @study_public.byline }}</SubHead>
        <Title1>{{ @study_public.title }}</Title1>
        <Case value={{@task_completed?}}>
          <True> <!-- Task completed -->
            <BodyLarge>{{dgettext("eyra-survey", "completed.message")}}</BodyLarge>
          </True>
          <False> <!-- Task not completed -->
            <BodyLarge>{{ @study_public.description }}</BodyLarge>
            <Spacing value="L" />
            <Title6>{{dgettext("eyra-survey", "duration.public.label")}}</Title6>
            <BodyMedium>{{ @study_public.duration }}</BodyMedium>

            <Spacing value="L" />
            <Title6>{{dgettext("eyra-survey", "config.devices.title")}}</Title6>
            <Bullet :if={{@study_public.phone_enabled}} image={{Routes.static_path(@socket, "/images/bullit.svg")}}>
              <BodyMedium>{{dgettext("eyra-survey", "phone.enabled.label")}}</BodyMedium>
            </Bullet>
            <Bullet :if={{@study_public.tablet_enabled}} image={{Routes.static_path(@socket, "/images/bullit.svg")}}>
              <BodyMedium>{{dgettext("eyra-survey", "tablet.enabled.label")}}</BodyMedium>
            </Bullet>
            <Bullet :if={{@study_public.desktop_enabled}} image={{Routes.static_path(@socket, "/images/bullit.svg")}}>
              <BodyMedium>{{dgettext("eyra-survey", "desktop.enabled.label")}}</BodyMedium>
            </Bullet>

            <Spacing value="L" />
            <PrimaryLiveViewButton :if={{not @participant?}} label={{ dgettext("eyra-survey", "apply.button") }} event="signup" />
            <PrimaryButton :if={{@task_available?}} label={{ dgettext("eyra-survey", "goto.survey") }} path={{@survey_tool.survey_url}} bg_color="bg-grey1" />
            </False>
        </Case>
        <Case value={{@participant?}}>
          <True>
            <Spacing value="L" />
            <SecondaryLiveViewButton :if={{@participant?}} label={{ dgettext("eyra-survey", "withdraw.button") }} event="withdraw" />
          </True>
        </Case>
      </ContentArea>
    """
  end
end
