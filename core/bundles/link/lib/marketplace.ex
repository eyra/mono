defmodule Link.Marketplace do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :marketplace

  alias Systems.{
    Pool,
    NextAction,
    Campaign
  }

  alias Core.Accounts

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias Link.Marketplace.Card, as: CardVM

  alias Frameworks.Pixel.Card.SecondaryCampaign
  alias Frameworks.Pixel.Text.{Title2}
  alias Frameworks.Pixel.Grid.{DynamicGrid}

  data(next_best_action, :any)
  data(highlighted_count, :any)
  data(owned_campaigns, :any)
  data(subject_count, :any)
  data(available_campaigns, :any)
  data(available_count, :any)
  data(current_user, :any)

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    next_best_action = NextAction.Context.next_best_action(url_resolver(socket), user)
    user = socket.assigns[:current_user]

    preload = Campaign.Model.preload_graph(:full)

    subject_campaigns = Campaign.Context.list_subject_campaigns(user, preload: preload)

    highlighted_count = Enum.count(subject_campaigns)

    excluded_campaigns = Campaign.Context.list_excluded_campaigns(subject_campaigns)

    exclude = subject_campaigns ++ excluded_campaigns

    exclusion_list =
      exclude
      |> Stream.map(fn campaign -> campaign.id end)
      |> Enum.into(MapSet.new())

    available_campaigns =
      Campaign.Context.list_by_submission_status([:accepted],
        exclude: exclusion_list,
        preload: preload
      )
      |> filter(socket)
      |> sort_by_open_spot_count()
      |> Enum.map(&CardVM.primary_campaign(&1, socket))

    subject_count = Enum.count(subject_campaigns)
    available_count = Enum.count(available_campaigns)

    socket =
      socket
      |> update_menus()
      |> assign(next_best_action: next_best_action)
      |> assign(highlighted_count: highlighted_count)
      |> assign(subject_count: subject_count)
      |> assign(available_campaigns: available_campaigns)
      |> assign(available_count: available_count)

    {:ok, socket}
  end

  defp sort_by_open_spot_count(campaigns) when is_list(campaigns) do
    Enum.sort_by(campaigns, &Campaign.Context.open_spot_count/1, :desc)
  end

  defp filter(campaigns, socket) when is_list(campaigns) do
    Enum.filter(campaigns, &filter(&1, socket))
  end

  defp filter(
         %{
           promotion: %{submission: %{criteria: submission_criteria} = submission}
         },
         %{assigns: %{current_user: user}}
       ) do
    user_features = Accounts.get_features(user)

    released? = Pool.Context.published_status(submission) == :released
    eligitable? = Pool.CriteriaModel.eligitable?(submission_criteria, user_features)

    released? and eligitable?
  end

  def handle_info({:handle_auto_save_done, _}, socket) do
    socket |> update_menus()
    {:noreply, socket}
  end

  def handle_info({:card_click, %{action: :edit, id: id}}, socket) do
    {:noreply,
     push_redirect(socket,
       to: CoreWeb.Router.Helpers.live_path(socket, Systems.Campaign.ContentPage, id)
     )}
  end

  def handle_info(
        {:card_click, %{action: :public, id: id}},
        %{assigns: %{uri_path: uri_path}} = socket
      ) do
    promotion_path = Routes.live_path(socket, Systems.Promotion.LandingPage, id, back: uri_path)
    {:noreply, push_redirect(socket, to: promotion_path)}
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
    ~F"""
    <Workspace title={dgettext("eyra-ui", "marketplace.title")} menus={@menus}>
      <ContentArea>
        <MarginY id={:page_top} />
        <div :if={@next_best_action}>
          <NextAction.HighlightView vm={@next_best_action} />
          <div class="mt-6 lg:mt-10" />
        </div>
        <Case value={@subject_count > 0}>
          <True>
          </True>
        </Case>
        <Case value={render_empty?(assigns)}>
          <False>
            <Spacing :if={@subject_count > 0} value="XL" />
            <Title2>
              {dgettext("eyra-campaign", "campaign.all.title")}
              <span class="text-primary">
                {@available_count}</span>
            </Title2>
            <DynamicGrid>
              <div :for={card <- @available_campaigns} class="mb-1">
                <SecondaryCampaign
                  id={card.id}
                  path_provider={CoreWeb.Endpoint}
                  card={card}
                  click_event_data={%{action: :public, id: card.open_id}}
                />
              </div>
            </DynamicGrid>
          </False>
          <True>
            <Spacing :if={@subject_count > 0} value="XXL" />
            <Empty
              title={dgettext("eyra-marketplace", "empty.title")}
              body={dgettext("eyra-marketplace", "empty.description")}
              illustration="cards"
            />
          </True>
        </Case>
      </ContentArea>
    </Workspace>
    """
  end
end
