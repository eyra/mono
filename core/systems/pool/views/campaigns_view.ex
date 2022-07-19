defmodule Systems.Pool.CampaignsView do
  use CoreWeb.UI.LiveComponent

  alias Systems.{
    Pool,
    NextAction
  }

  alias Core.Accounts
  alias CoreWeb.UI.ContentList
  alias Frameworks.Pixel.Selector.Selector
  alias Frameworks.Pixel.Text.{Title2}

  prop(props, :map, required: true)

  data(campaigns, :list)
  data(filtered_campaigns, :map)
  data(filter_labels, :list)

  # Handle Selector Update
  def update(%{active_item_ids: active_filters, selector_id: :campaign_filters}, socket) do
    {
      :ok,
      socket
      |> assign(active_filters: active_filters)
      |> prepare_campaigns()
    }
  end

  # Primary Update
  def update(
        %{id: id, props: %{campaigns: campaigns}} = _params,
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
      NextAction.Context.clear_next_action(user, Pool.ReviewSubmission)
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

  def render(assigns) do
    ~F"""
    <ContentArea>
      <MarginY id={:page_top} />
      <div class="flex flex-row gap-3 items-center">
        <div class="font-label text-label">Filter:</div>
        <Selector id={:campaign_filters} items={@filter_labels} parent={%{type: __MODULE__, id: @id}} />
      </div>
      <Spacing value="L" />
      <Title2>{dgettext("link-studentpool", "tabbar.item.campaigns")}: <span class="text-primary">{Enum.count(@filtered_campaigns)}</span></Title2>
      <Case value={Enum.count(@campaigns) > 0}>
        <True>
          <ContentList items={@filtered_campaigns} />
        </True>
        <False>
          <Empty
            title={dgettext("link-studentpool", "campaigns.empty.title")}
            body={dgettext("link-studentpool", "campaigns.empty.description")}
            illustration="items"
          />
        </False>
      </Case>
    </ContentArea>
    """
  end
end
