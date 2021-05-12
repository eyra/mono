defmodule Link.Dashboard do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  import Core.Authorization
  alias Core.Studies
  alias Core.Studies.Study
  alias Core.SurveyTools

  alias CoreWeb.ViewModel.Card, as: CardVM

  alias EyraUI.Card.{PrimaryStudy, SecondaryStudy, ButtonCard}
  alias EyraUI.Hero.HeroLarge
  alias EyraUI.Container.{ContentArea}
  alias EyraUI.Text.{Title2}
  alias EyraUI.Grid.{DynamicGrid}

  data(highlighted_count, :any)
  data(owned_studies, :any)
  data(subject_studies, :any)
  data(available_studies, :any)
  data(available_count, :any)
  data(current_user, :any)

  def mount(_params, _session, socket) do
    user = socket.assigns[:current_user]
    preload = [:survey_tools]

    owned_studies =
      user
      |> Studies.list_owned_studies(preload: preload)
      |> Enum.map(&CardVM.primary_study(&1, socket))

    subject_studies =
      user
      |> Studies.list_subject_studies(preload: preload)
      |> Enum.map(&CardVM.primary_study(&1, socket))

    highlighted_studies = owned_studies ++ subject_studies
    highlighted_count = Enum.count(highlighted_studies)

    exclusion_list =
      highlighted_studies
      |> Stream.map(fn study -> study.id end)
      |> Enum.into(MapSet.new())

    available_studies =
      Studies.list_studies_with_published_survey(exclude: exclusion_list, preload: preload)
      |> Enum.map(&CardVM.primary_study(&1, socket))

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

  def handle_info({:handle_click, %{action: :edit, card_id: card_id}}, socket) do
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, CoreWeb.Study.Edit, card_id))}
  end

  def handle_info({:handle_click, %{action: :public, card_id: card_id}}, socket) do
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, CoreWeb.Study.Public, card_id))}
  end

  def handle_event("create_study", _params, socket) do
    study = create_study(socket)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, CoreWeb.Study.Edit, study.id))}
  end

  defp create_study(socket) do
    current_user = socket.assigns.current_user

    changeset =
      %Study{}
      |> Study.changeset(%{title: "Nieuwe studie"})

    # temp ensure every study has at least one survey
    with {:ok, study} <- Studies.create_study(changeset, current_user),
         {:ok, _author} <- Studies.add_author(study, current_user),
         {:ok, _survey_tool} <-
           SurveyTools.create_survey_tool(create_survey_tool_attrs(study.title), study) do
      study
    end
  end

  defp create_survey_tool_attrs(title) do
    %{
      title: title,
      phone_enabled: true,
      tablet_enabled: true,
      desktop_enabled: true,
      reward_currency: :eur,
      image_url:
        "https://images.unsplash.com/photo-1541701494587-cb58502866ab?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=3900&q=80"
    }
  end

  def render(assigns) do
    ~H"""
      <HeroLarge title={{ dgettext("eyra-study", "study.index.title") }}
            subtitle={{dgettext("eyra-study", "study.index.subtitle")}} />

      <ContentArea>
        <Title2>
          {{ dgettext("eyra-study", "study.highlighted.title") }}
          <span class="text-primary"> {{ @highlighted_count }}</span>
        </Title2>
        <DynamicGrid>
          <div :for={{ card <- @owned_studies  }} >
            <PrimaryStudy conn={{@socket}} path_provider={{Routes}} card={{card}} click_event_data={{%{action: :edit, card_id: card.id } }} />
          </div>
          <div :for={{ card <- @subject_studies  }} >
            <PrimaryStudy conn={{@socket}} path_provider={{Routes}} card={{card}} click_event_data={{%{action: :public, card_id: card.id } }} />
          </div>
          <div :if={{ can_access?(@current_user, CoreWeb.Study.New) }} >
            <ButtonCard
              title={{dgettext("eyra-study", "add.card.title")}}
              image={{Routes.static_path(@socket, "/images/plus-primary.svg")}}
              event="create_study" />
          </div>
        </DynamicGrid>
        <div class="mt-12 lg:mt-16"/>
        <Title2>
          {{ dgettext("eyra-study", "study.all.title") }}
          <span class="text-primary"> {{ @available_count }}</span>
        </Title2>
        <DynamicGrid>
          <div :for={{ card <- @available_studies  }} class="mb-1" >
            <SecondaryStudy conn={{@socket}} path_provider={{Routes}} card={{card}} click_event_data={{%{action: :public, card_id: card.id } }} />
          </div>
        </DynamicGrid>
      </ContentArea>
    """
  end
end
