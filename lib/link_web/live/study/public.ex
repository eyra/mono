defmodule LinkWeb.Study.Public do
  @moduledoc """
  The public page for participants.
  """
  use LinkWeb, :live_view
  use LinkWeb.LiveViewPowHelper
  alias EyraUI.Hero.HeroSmall
  alias EyraUI.Container.ContentArea
  alias EyraUI.Text.{Title1, Title6, SubHead, BodyMedium}
  alias EyraUI.Button.{PrimaryLiveViewButton}

  alias Link.Studies
  alias Link.Studies.{Study, StudyPublic}

  data study_public, :any

  def mount(%{"id" => id}, _session, socket) do
    study_public = load_view_model(id)

    socket =
      socket
      |> assign(study_public: study_public)

    {:ok, socket}
  end

  def load_view_model(id) do
    study = Studies.get_study!(id)
    study_survey = study |> load_survey_tool()
    StudyPublic.create(study, study_survey)
  end

  def load_survey_tool(%Study{} = study) do
    case study |> Studies.list_survey_tools() do
      [survey_tool] -> survey_tool
      [survey_tool | _] -> survey_tool
      _ -> raise "Expected at least one survey tool for study #{study.title}"
    end
  end

  def handle_event("apply", _params, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <HeroSmall title={{ dgettext("eyra-study", "study.public.title") }} />
      <ContentArea>
        <SubHead>{{ @study_public.byline }}</SubHead>
        <Title1>{{ @study_public.title }}</Title1>
        <Title6>{{dgettext("eyra-survey", "duration.public.label")}}</Title6>
        <BodyMedium>{{ @study_public.duration }}</BodyMedium>
        <div class="mb-6"/>
        <Title6>{{dgettext("eyra-survey", "info.public.label")}}</Title6>
        <BodyMedium>{{ @study_public.description }}</BodyMedium>
        <div class="mb-8"/>
        <PrimaryLiveViewButton label={{ dgettext("eyra-survey", "apply.button") }} event="apply" />
      </ContentArea>
    """
  end
end
