defmodule LinkWeb.Dashboard do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view
  import Link.Authorization
  import Link.Accounts
  alias Link.Studies
  alias EyraUI.Card.{PrimaryStudy, SecondaryStudy, ButtonCard}
  alias EyraUI.Hero.HeroLarge
  alias EyraUI.Container.{ContentArea}
  alias EyraUI.Text.{BodyLarge, Title2}
  alias EyraUI.Grid.{DynamicGrid}

  data highlighted_count, :any
  data owned_studies, :any
  data subject_studies, :any
  data available_studies, :any
  data available_count, :any
  data current_user, :any

  def mount(_params, session, socket) do
    user = get_user(socket, session)
    profile = get_profile(user)
    socket = assign(socket, current_user_profile: profile)

    owned_studies = user |> Studies.list_owned_studies()
    subject_studies = user |> Studies.list_subject_studies()

    highlighted_studies = owned_studies ++ subject_studies
    highlighted_count = Enum.count(highlighted_studies)

    exclusion_list =
      highlighted_studies
      |> Stream.map(fn study -> study.id end)
      |> Enum.into(MapSet.new())

    available_studies = Studies.list_studies_with_published_survey(exclude: exclusion_list)
    available_count = Enum.count(available_studies)

    socket =
      socket
      |> assign(highlighted_count: highlighted_count)
      |> assign(owned_studies: owned_studies)
      |> assign(subject_studies: subject_studies)
      |> assign(available_studies: available_studies)
      |> assign(available_count: available_count)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
      <HeroLarge title={{ dgettext("eyra-study", "study.index.title") }}
            subtitle={{dgettext("eyra-study", "study.index.subtitle")}} />

      <ContentArea>
        <BodyLarge>
          {{dgettext("eyra-study", "dashboard.page.description")}}
        </BodyLarge>
        <div class="mt-12 lg:mt-16"/>
        <Title2>
          {{ dgettext("eyra-study", "study.highlighted.title") }}
          <span class="text-primary"> {{ @highlighted_count }}</span>
        </Title2>
        <DynamicGrid>
          <div :for={{ study <- @owned_studies  }} >
            <PrimaryStudy
              title={{study.title}}
              button_label={{ dgettext("eyra-study", "edit.button") }}
              to={{Routes.live_path(@socket, LinkWeb.Study.Edit, study.id)}} />
          </div>
          <div :for={{ study <- @subject_studies  }} >
            <PrimaryStudy
              title={{study.title}}
              button_label={{ dgettext("eyra-study", "open.button") }}
              to={{Routes.live_path(@socket, LinkWeb.Study.Public, study.id)}}/>
          </div>
          <div :if={{ can_access?(@current_user, LinkWeb.Study.New) }} >
            <ButtonCard
              socket={{@socket}}
              title={{dgettext("eyra-study", "add.card.title")}}
              path={{Routes.live_path(@socket, LinkWeb.Study.New)}}/>
          </div>
        </DynamicGrid>
        <div class="mt-12 lg:mt-16"/>
        <Title2>
          {{ dgettext("eyra-study", "study.all.title") }}
          <span class="text-primary"> {{ @available_count }}</span>
        </Title2>
        <DynamicGrid>
          <div :for={{ study <- @available_studies  }} class="mb-1" >
            <SecondaryStudy
              title={{study.title}}
              button_label={{ dgettext("eyra-study", "open.button") }}
              to={{Routes.live_path(@socket, LinkWeb.Study.Public, study.id)}} />
          </div>
        </DynamicGrid>
      </ContentArea>
    """
  end
end
