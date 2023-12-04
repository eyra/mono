defmodule Link.Marketplace.Page do
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

  import CoreWeb.Layouts.Workspace.Component
  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.Text

  def mount(_params, _session, %{assigns: %{current_user: user} = assigns} = socket) do
    next_best_action = NextAction.Public.next_best_action(user)
    user = socket.assigns[:current_user]

    preload = Campaign.Model.preload_graph(:down)

    subject_campaigns = Campaign.Public.list_subject_campaigns(user, preload: preload)
    excluded_campaigns = Campaign.Public.list_excluded_campaigns(subject_campaigns)
    exclude = subject_campaigns ++ excluded_campaigns

    exclusion_list =
      exclude
      |> Stream.map(fn campaign -> campaign.id end)
      |> Enum.into(MapSet.new())

    campaigns =
      Pool.Public.list_by_user(user)
      |> Campaign.Public.list_by_pools_and_submission_status([:accepted],
        exclude: exclusion_list,
        preload: preload
      )
      |> filter_campaigns(socket)
      |> sort_by_open_spot_count()
      |> Enum.map(&ViewModelBuilder.view_model(&1, {__MODULE__, :card}, assigns))

    campaign_count = Enum.count(campaigns)

    socket =
      socket
      |> update_menus()
      |> assign(next_best_action: next_best_action)
      |> assign(campaigns: campaigns)
      |> assign(campaign_count: campaign_count)

    {:ok, socket}
  end

  defp sort_by_open_spot_count(campaigns) when is_list(campaigns) do
    Enum.sort_by(campaigns, &Campaign.Public.open_spot_count/1, :desc)
  end

  defp filter_campaigns(campaigns, socket) when is_list(campaigns) do
    Enum.filter(campaigns, &filter_campaign(&1, socket))
  end

  defp filter_campaign(
         campaign,
         %{assigns: %{current_user: user}}
       ) do
    case Campaign.Public.validate_open(campaign, user) do
      :ok -> true
      _ -> false
    end
  end

  def handle_info({:handle_auto_save_done, _}, socket) do
    socket |> update_menus()
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "card_clicked",
        %{"item" => card_id},
        %{assigns: %{campaigns: campaigns}} = socket
      ) do
    card_id = String.to_integer(card_id)
    %{path: path} = Enum.find(campaigns, &(&1.id == card_id))

    {
      :noreply,
      push_redirect(socket, to: path)
    }
  end

  @impl true
  def handle_event("menu-item-clicked", %{"action" => action}, socket) do
    # toggle menu
    {:noreply, push_redirect(socket, to: action)}
  end

  def render_empty?(%{campaign_count: campaign_count}) do
    not feature_enabled?(:marketplace) or campaign_count == 0
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={dgettext("eyra-ui", "marketplace.title")} menus={@menus}>
      <Area.content>
        <Margin.y id={:page_top} />
        <%= if @next_best_action do %>
        <div>
          <NextAction.View.highlight {@next_best_action} />
          <div class="mt-6 lg:mt-10" />
        </div>
        <% end %>
        <%= if render_empty?(assigns) do %>
          <.empty
                title={dgettext("eyra-marketplace", "empty.title")}
                body={dgettext("eyra-marketplace", "empty.description")}
                illustration="cards"
              />
        <% else %>
          <Text.title2>
              <%= dgettext("eyra-campaign", "campaign.all.title") %>
              <span class="text-primary"><%= @campaign_count %></span>
          </Text.title2>
          <Grid.dynamic>
            <%= for card <- @campaigns do %>
              <div class="mb-1">
                <Campaign.CardView.secondary
                  card={card}
                />
              </div>
            <% end %>
          </Grid.dynamic>
        <% end %>
      </Area.content>
    </.workspace>
    """
  end
end