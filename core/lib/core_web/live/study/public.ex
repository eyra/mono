defmodule CoreWeb.Study.Public do
  @moduledoc """
  The public study screen.
  """
  use CoreWeb, :live_view

  alias EyraUI.Spacing
  alias EyraUI.CampaignBanner
  alias EyraUI.Panel.Panel
  alias EyraUI.Container.ContentArea
  alias EyraUI.Text.{Title1, Title2, Title3, BodyLarge, Intro}
  alias EyraUI.Button.{PrimaryLiveViewButton, PrimaryButton, SecondaryLiveViewButton, BackButton}
  alias EyraUI.Case.{Case, True, False}
  alias EyraUI.Hero.{HeroImage, HeroBanner}
  alias EyraUI.Card.Highlight

  alias CoreWeb.Devices

  alias Core.Studies
  alias Core.Studies.{Study, StudyPublic}
  alias Core.SurveyTools
  alias Core.SurveyTools.SurveyToolTask

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

  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns[:current_user]
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

    {:noreply, push_redirect(socket, to: Routes.live_path(socket, CoreWeb.Dashboard))}
  end

  def handle_info({:delivered_email, _email}, socket) do
    # TBD
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <HeroImage
        title={{@study_public.title}}
        subtitle={{@study_public.themes}}
        image_info={{@study_public.image_info}}
      >
        <template slot="call_to_action">
          <PrimaryLiveViewButton :if={{not @participant?}} label={{ dgettext("eyra-survey", "apply.button") }} event="signup" />
          <PrimaryButton :if={{@task_available?}} label={{ dgettext("eyra-survey", "goto.survey") }} path={{@survey_tool.survey_url}} />
        </template>
      </HeroImage>
      <HeroBanner title={{@study_public.organisation_name}} subtitle={{ @study_public.byline }} icon_url={{ Routes.static_path(@socket, "/images/#{@study_public.organisation_icon}.svg") }}/>
      <ContentArea>
        <Case value={{@task_completed?}}>
          <True> <!-- Task completed -->
            <BodyLarge>{{dgettext("eyra-survey", "completed.message")}}</BodyLarge>
          </True>
          <False> <!-- Task not completed -->
            <div class="ml-8 mr-8 text-center">
              <Title1>{{@study_public.subtitle}}</Title1>
            </div>

            <div class="mb-12 sm:mb-16" />
            <div class="grid grid-cols-1 gap-6 sm:gap-8 sm:grid-cols-{{ Enum.count(@study_public.highlights) }}">
              <div :for={{ highlight <- @study_public.highlights }} class="bg-grey5 rounded">
                <Highlight title={{highlight.title}} text={{highlight.text}} />
              </div>
            </div>
            <div class="mb-12 sm:mb-16" />

            <Title2>{{dgettext("eyra-survey", "expectations.public.label")}}</Title2>
            <Spacing value="M" />
            <BodyLarge>{{ @study_public.expectations }}</BodyLarge>
            <Spacing value="M" />
            <Title2>{{dgettext("eyra-survey", "description.public.label")}}</Title2>
            <Spacing value="M" />
            <BodyLarge>{{ @study_public.description }}</BodyLarge>
            <Spacing value="L" />

            <CampaignBanner
              photo_url={{@study_public.banner_photo_url}}
              placeholder_photo_url={{ Routes.static_path(@socket, "/images/profile_photo_default.svg") }}
              title={{@study_public.banner_title}}
              subtitle={{@study_public.banner_subtitle}}
              url={{@study_public.banner_url}}
            />
            <Spacing value="L" />
            <Panel bg_color="bg-grey5" align="text-center">
              <template slot="title">
                <Title3>Benieuwd naar de resultaten van dit onderzoek?</Title3>
              </template>
              <Intro>Je kan je hier inschrijven voor de nieuwsbrief. </Intro>
              <Spacing value="M" />
              <SecondaryLiveViewButton label="Houd me op de hoogte" event="register" color="text-primary"/>
            </Panel>

            <Spacing value="L" />
            <Devices label={{ dgettext("eyra-survey", "devices.available.label") }} devices={{ @study_public.devices }}/>
            <Spacing value="XL" />

            <div class="flex flex-row">
              <div :if={{not @participant?}} class="mr-4">
                <PrimaryLiveViewButton label={{ dgettext("eyra-survey", "apply.button") }} event="signup" />
              </div>
              <div :if={{@task_available?}} class="mr-4">
                <PrimaryButton label={{ dgettext("eyra-survey", "goto.survey") }} to={{@survey_tool.survey_url}} />
              </div>
              <div :if={{@participant?}}>
                <SecondaryLiveViewButton label={{ dgettext("eyra-survey", "withdraw.button") }} event="withdraw" />
              </div>
            </div>
          </False>
          </Case>
          <Spacing value="M" />
          <div class="flex">
            <BackButton label="Terug naar overzicht" path={{ Routes.live_path(@socket, CoreWeb.Dashboard) }}/>
          </div>
      </ContentArea>
    """
  end
end
