defmodule Systems.Pool.CampaignsView do
  use CoreWeb, :live_component

  alias Systems.{
    Pool,
    NextAction
  }

  import CoreWeb.UI.Empty
  import CoreWeb.UI.Content

  alias Core.Accounts
  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text

  # Handle Selector Update
  @impl true
  def update(%{active_item_ids: active_filters, selector_id: :campaign_filters}, socket) do
    {
      :ok,
      socket
      |> assign(active_filters: active_filters)
      |> prepare_campaigns()
    }
  end

  # Primary Update
  @impl true
  def update(
        %{id: id, campaigns: campaigns} = _params,
        socket
      ) do
    clear_review_submission_next_action()

    filter_labels = Pool.CampaignStatus.labels([])

    {
      :ok,
      socket
      |> assign(
        id: id,
        campaigns: campaigns,
        active_filters: [],
        filter_labels: filter_labels
      )
      |> prepare_campaigns()
    }
  end

  defp clear_review_submission_next_action do
    for user <- Accounts.list_pool_admins() do
      NextAction.Public.clear_next_action(user, Pool.ReviewSubmission)
    end
  end

  defp filter(campaigns, nil), do: campaigns
  defp filter(campaigns, []), do: campaigns

  defp filter(campaigns, filters) do
    campaigns |> Enum.filter(&(&1.tag.id in filters))
  end

  defp prepare_campaigns(
         %{assigns: %{campaigns: campaigns, active_filters: active_filters}} = socket
       ) do
    filtered_campaigns =
      campaigns
      |> filter(active_filters)

    socket
    |> assign(filtered_campaigns: filtered_campaigns)
  end

  attr(:campaigns, :list, required: true)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <%= if Enum.count(@campaigns) > 0 do %>
        <div class="flex flex-row gap-3 items-center">
          <div class="font-label text-label">Filter:</div>
          <.live_component
          module={Selector} id={:campaign_filters} type={:label} items={@filter_labels} parent={%{type: __MODULE__, id: @id}} />
        </div>
        <.spacing value="L" />
        <Text.title2><%=dgettext("link-studentpool", "tabbar.item.campaigns") %> <span class="text-primary"><%= Enum.count(@filtered_campaigns) %></span></Text.title2>
        <.list items={@filtered_campaigns} />
      <% else %>
        <.empty
          title={dgettext("link-studentpool", "campaigns.empty.title")}
          body={dgettext("link-studentpool", "campaigns.empty.description")}
          illustration="items"
        />
      <% end %>
      </Area.content>
    </div>
    """
  end
end
