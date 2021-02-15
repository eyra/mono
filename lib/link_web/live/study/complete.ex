defmodule LinkWeb.Study.Complete do
  @moduledoc """
  The public study screen.
  """
  use LinkWeb, :live_view

  alias EyraUI.Hero.HeroSmall
  alias EyraUI.Container.ContentArea
  alias EyraUI.Text.{Title1, SubHead, BodyLarge}
  alias EyraUI.Spacing

  alias Link.Studies
  alias Link.Studies.{Study, StudyPublic}
  alias Link.SurveyTools

  data study, :any
  data survey_tool, :any
  data task_available?, :boolean
  data task_completed?, :boolean
  data participant?, :boolean
  data study_public, :any

  def mount(%{"id" => id}, session, socket) do
    user = get_user(socket, session)
    study = Studies.get_study!(id)
    survey_tool = load_survey_tool(study)
    study_public = StudyPublic.create(study, survey_tool)

    survey_tool
    |> SurveyTools.get_or_create_task!(user)
    |> SurveyTools.complete_task!()

    {:ok,
     socket
     |> assign(
       user: user,
       study: study,
       survey_tool: survey_tool,
       study_public: study_public
     )}
  end

  def load_survey_tool(%Study{} = study) do
    case Studies.list_survey_tools(study) do
      [] -> raise "Expected at least one survey tool for study #{study.title}"
      [survey_tool | _] -> survey_tool
    end
  end

  def render(assigns) do
    ~H"""
      <HeroSmall title={{ dgettext("eyra-study", "study.public.title") }} />
      <ContentArea>
        <SubHead>{{ @study_public.byline }}</SubHead>
        <Title1>{{ @study_public.title }}</Title1>
        <Spacing value="S" />
        <BodyLarge>{{dgettext("eyra-survey", "thank.you.message")}}</BodyLarge>
      </ContentArea>
    """
  end
end
