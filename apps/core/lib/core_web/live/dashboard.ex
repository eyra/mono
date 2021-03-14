defmodule CoreWeb.Dashboard do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  import Core.Authorization
  import Core.Accounts
  alias Core.Studies
  alias EyraUI.Card.{PrimaryStudy, SecondaryStudy, ButtonCard}
  alias EyraUI.Hero.HeroLarge
  alias EyraUI.Container.{ContentArea}
  alias EyraUI.Text.{BodyLarge, Title2}
  alias EyraUI.Grid.{DynamicGrid}

  data(highlighted_count, :any)
  data(owned_studies, :any)
  data(subject_studies, :any)
  data(available_studies, :any)
  data(available_count, :any)
  data(current_user, :any)
  data(path_provider, :any)

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
              to={{@path_provider.live_path(@socket, CoreWeb.Study.Edit, study.id)}} />
          </div>
          <div :for={{ study <- @subject_studies  }} >
            <PrimaryStudy
              title={{study.title}}
              button_label={{ dgettext("eyra-study", "open.button") }}
              to={{@path_provider.live_path(@socket, CoreWeb.Study.Public, study.id)}}/>
          </div>
          <div :if={{ can_access?(@current_user, CoreWeb.Study.New) }} >
            <ButtonCard
              title={{dgettext("eyra-study", "add.card.title")}}
              path={{@path_provider.live_path(@socket, CoreWeb.Study.New)}}
              image={{@path_provider.static_path(@socket, "/images/plus-primary.svg")}} />
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
              to={{@path_provider.live_path(@socket, CoreWeb.Study.Public, study.id)}} />
          </div>
        </DynamicGrid>
      </ContentArea>
    """
  end
end
