defmodule Systems.Advert.ListView do
  use CoreWeb, :live_component

  alias Systems.{
    Pool,
    NextAction
  }

  import Frameworks.Pixel.Empty
  import Frameworks.Pixel.Content

  alias Core.Accounts
  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text
  alias Systems.Advert

  @impl true
  def update(
        %{id: id, adverts: adverts} = _params,
        socket
      ) do
    clear_review_submission_next_action()

    filter_labels = Advert.Status.labels([])

    {
      :ok,
      socket
      |> assign(
        id: id,
        adverts: adverts,
        active_filters: [],
        filter_labels: filter_labels
      )
      |> prepare_adverts()
      |> compose_child(:advert_filters)
    }
  end

  @impl true
  def compose(:advert_filters, %{filter_labels: items}) do
    %{
      module: Selector,
      params: %{
        items: items,
        type: :label
      }
    }
  end

  defp clear_review_submission_next_action do
    for user <- Accounts.list_pool_admins() do
      NextAction.Public.clear_next_action(user, Pool.ReviewSubmission)
    end
  end

  defp filter(adverts, nil), do: adverts
  defp filter(adverts, []), do: adverts

  defp filter(adverts, filters) do
    adverts |> Enum.filter(&(&1.tag.id in filters))
  end

  defp prepare_adverts(%{assigns: %{adverts: adverts, active_filters: active_filters}} = socket) do
    filtered_adverts =
      adverts
      |> filter(active_filters)

    socket
    |> assign(filtered_adverts: filtered_adverts)
  end

  @impl true
  def handle_event(
        "active_item_ids",
        %{active_item_ids: active_filters, selector_id: :advert_filters},
        socket
      ) do
    {
      :noreply,
      socket
      |> assign(active_filters: active_filters)
      |> prepare_adverts()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <%= if Enum.count(@adverts) > 0 do %>
        <div class="flex flex-row gap-3 items-center">
          <div class="font-label text-label">Filter:</div>
          <.child name={:advert_filters} fabric={@fabric} />
        </div>
        <.spacing value="L" />
        <Text.title2><%=dgettext("link-studentpool", "tabbar.item.adverts") %> <span class="text-primary"><%= Enum.count(@filtered_adverts) %></span></Text.title2>
        <.list items={@filtered_adverts} />
      <% else %>
        <.empty
          title={dgettext("link-studentpool", "adverts.empty.title")}
          body={dgettext("link-studentpool", "adverts.empty.description")}
          illustration="items"
        />
      <% end %>
      </Area.content>
    </div>
    """
  end
end
