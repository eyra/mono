defmodule Link.Marketplace do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :marketplace

  alias Systems.NextAction
  alias Core.Studies
  alias Core.Survey.Tool, as: SurveyTool
  alias Core.Lab.Tool, as: LabTool

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias Link.Marketplace.Card, as: CardVM

  alias EyraUI.Card.{PrimaryStudy, SecondaryStudy}
  alias EyraUI.Text.{Title2}
  alias EyraUI.Grid.{DynamicGrid}

  data(next_best_action, :any)
  data(highlighted_count, :any)
  data(owned_studies, :any)
  data(subject_studies, :any)
  data(available_studies, :any)
  data(available_count, :any)
  data(current_user, :any)

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    next_best_action = NextAction.Context.next_best_action(url_resolver(socket), user)
    user = socket.assigns[:current_user]
    preload = [survey_tool: [:promotion], lab_tool: [:promotion, :time_slots]]

    subject_studies =
      user
      |> Studies.list_subject_studies(preload: preload)
      |> Enum.map(&CardVM.primary_study(&1, socket))

    highlighted_studies = subject_studies
    highlighted_count = Enum.count(subject_studies)

    exclusion_list =
      highlighted_studies
      |> Stream.map(fn study -> study.id end)
      |> Enum.into(MapSet.new())

    available_studies =
      Studies.list_accepted_studies([LabTool, SurveyTool],
        exclude: exclusion_list,
        preload: preload
      )
      |> Enum.map(&CardVM.primary_study(&1, socket))

    available_count = Enum.count(available_studies)

    socket =
      socket
      |> update_menus()
      |> assign(next_best_action: next_best_action)
      |> assign(highlighted_count: highlighted_count)
      |> assign(subject_studies: subject_studies)
      |> assign(available_studies: available_studies)
      |> assign(available_count: available_count)

    {:ok, socket}
  end


  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  def handle_info({:card_click, %{action: :edit, id: id}}, socket) do
    {:noreply,
     push_redirect(socket, to: CoreWeb.Router.Helpers.live_path(socket, Link.Survey.Content, id))}
  end

  def handle_info({:card_click, %{action: :public, id: id}}, socket) do
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, Link.Promotion.Public, id))}
  end

  @impl true
  def handle_event("menu-item-clicked", %{"action" => action}, socket) do
    # toggle menu
    {:noreply, push_redirect(socket, to: action)}
  end

  def render_empty?(%{available_count: available_count}) do
    not feature_enabled?(:marketplace) or available_count == 0
  end

  def render(assigns) do
    ~H"""
        <Workspace
          title={{ dgettext("eyra-ui", "marketplace.title") }}
          menus={{ @menus }}
        >
          <ContentArea>
            <MarginY id={{:page_top}} />
            <div :if={{ @next_best_action }}>
              <NextAction.HighlightView vm={{ @next_best_action }}/>
              <div class="mt-6 lg:mt-10"/>
            </div>
            <Case value={{ render_empty?(assigns) }} >
              <False>
                <DynamicGrid>
                  <div :for={{ card <- @subject_studies  }} >
                    <PrimaryStudy conn={{@socket}} path_provider={{Routes}} card={{card}} click_event_data={{%{action: :public, id: card.open_id } }} />
                  </div>
                </DynamicGrid>
                <div class="mt-6 lg:mt-10"/>
                <Title2>
                  {{ dgettext("eyra-study", "study.all.title") }}
                  <span class="text-primary"> {{ @available_count }}</span>
                </Title2>
                <DynamicGrid>
                  <div :for={{ card <- @available_studies  }} class="mb-1" >
                    <SecondaryStudy conn={{@socket}} path_provider={{Routes}} card={{card}} click_event_data={{%{action: :public, id: card.open_id } }} />
                  </div>
                </DynamicGrid>
              </False>
              <True>
                <Empty
                  title={{ dgettext("eyra-marketplace", "empty.title") }}
                  body={{ dgettext("eyra-marketplace", "empty.description") }}
                  illustration="cards"
                />
              </True>
            </Case>
          </ContentArea>
        </Workspace>
    """
  end
end
