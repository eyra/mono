defmodule LinkWeb.Dashboard do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view
  use LinkWeb.LiveViewPowHelper
  import Link.Authorization
  import Link.Users
  alias Link.Studies
  alias EyraUI.{Hero}
  alias EyraUI.Container.{ContentArea}
  alias EyraUI.Text.{BodyLarge, Title2}
  alias EyraUI.Grid.{DynamicGrid}

  data highlighted_studies, :any
  data highlighted_count, :any
  data available_studies, :any
  data available_count, :any
  data current_user, :any

  def mount(_params, session, socket) do
    user = get_user(socket, session)
    profile = get_profile(user)
    socket = assign_current_user(socket, session, user, profile)

    owned_studies = user |> Studies.list_owned_studies()
    study_participations = user |> Studies.list_participations()

    exclusion_list =
      Stream.concat(owned_studies, study_participations)
      |> Stream.map(fn study -> study.id end)
      |> Enum.into(MapSet.new())

    available_studies = Studies.list_studies(exclude: exclusion_list)
    available_count = Enum.count(available_studies)

    highlighted_studies = owned_studies |> Enum.concat(study_participations)
    highlighted_count = Enum.count(exclusion_list)

    socket =
      socket
      |> assign(highlighted_studies: highlighted_studies)
      |> assign(highlighted_count: highlighted_count)
      |> assign(available_studies: available_studies)
      |> assign(available_count: available_count)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
      <Hero title={{ dgettext("eyra-study", "study.index.title") }}
            subtitle={{dgettext("eyra-study", "study.index.subtitle")}} />

      <ContentArea>
        <div class="flex flex-col">
          <BodyLarge>
            {{dgettext("eyra-study", "dashboard.page.description")}}
          </BodyLarge>
          <div class="flex-wrap">
            <Title2>
              {{ dgettext("eyra-study", "study.highlighted.title") }}
              <span class="text-primary"> {{ @highlighted_count }}</span>
            </Title2>
            <DynamicGrid>
                <div :for={{ study <- @highlighted_studies  }} >
                  {{ primary_study_card(@socket, study, "Bekijken") }}
                </div>
                <div :if={{ can?(@current_user, nil, LinkWeb.StudyController, :new) }} >
                  {{ button_card(@socket, dgettext("eyra-study", "add.card.title"), Routes.study_path(@socket, :new)) }}
                </div>
            </DynamicGrid>
          </div>
          <div class="flex-wrap mt-0">
            <Title2>
              {{ dgettext("eyra-study", "study.all.title") }}
              <span class="text-primary"> {{ @available_count }}</span>
            </Title2>
            <DynamicGrid>
              <div :for={{ study <- @available_studies  }} class="mb-1" >
                {{ secondary_study_card(@socket, study, "Bekijken") }}
              </div>
            </DynamicGrid>
          </div>
        </div>
      </ContentArea>
    """
  end
end
