defmodule Systems.Pool.MarketplaceView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text
  alias Systems.Advert
  alias Systems.Pool

  @impl true
  def update(%{pool: pool, items: items, years: years}, socket) do
    {
      :ok,
      socket
      |> assign(
        pool: pool,
        items: items,
        years: years,
        active_year: Map.get(socket.assigns, :active_year, nil),
        query: Map.get(socket.assigns, :query, nil),
        query_string: Map.get(socket.assigns, :query_string, "")
      )
      |> assign(:vm, Pool.MarketplaceViewBuilder.view_model(items, years))
      |> compose_child(:marketplace_search_bar)
      |> compose_child(:marketplace_year_selector)
    }
  end

  @impl true
  def compose(:marketplace_search_bar, %{
        vm: %{search_placeholder: placeholder},
        query_string: query_string
      }) do
    %{
      module: SearchBar,
      params: %{
        query_string: query_string,
        placeholder: placeholder,
        debounce: "200"
      }
    }
  end

  @impl true
  def compose(:marketplace_year_selector, %{vm: %{year_items: year_items}}) do
    %{
      module: Selector,
      params: %{
        items: year_items,
        type: :label,
        optional?: false
      }
    }
  end

  @impl true
  def handle_event(
        "search_query",
        %{query: query, query_string: query_string, source: %{name: :marketplace_search_bar}},
        socket
      ) do
    {:noreply, socket |> assign(query: query, query_string: query_string)}
  end

  @impl true
  def handle_event(
        "active_item_ids",
        %{active_item_ids: active_item_ids, source: %{name: :marketplace_year_selector}},
        socket
      ) do
    active_year =
      case List.first(active_item_ids) do
        :all -> nil
        year -> year
      end

    {:noreply, socket |> assign(active_year: active_year)}
  end

  @impl true
  def handle_event("card_clicked", %{"item" => card_id}, %{assigns: %{items: items}} = socket) do
    case Pool.MarketplaceViewBuilder.card_path(items, String.to_integer(card_id)) do
      {:ok, path} -> {:noreply, push_navigate(socket, to: path)}
      :stale -> {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="marketplace">
      <%= if Enum.empty?(@items) do %>
        <Text.body><%= dgettext("eyra-pool", "marketplace.empty.message") %></Text.body>
      <% else %>
        <div class="flex flex-row items-center gap-3">
          <div class="font-label text-label"><%= dgettext("eyra-pool", "marketplace.filter.label") %></div>
          <.child name={:marketplace_year_selector} fabric={@fabric} />
          <div class="flex-grow" />
          <div class="flex-shrink-0">
            <.child name={:marketplace_search_bar} fabric={@fabric} />
          </div>
        </div>
        <.spacing value="L" />
        <Grid.dynamic>
          <%= for card <- Pool.MarketplaceViewBuilder.filtered_cards(@items, @active_year, @query) do %>
            <Advert.CardView.dynamic card={card} target={@myself} />
          <% end %>
        </Grid.dynamic>
      <% end %>
    </div>
    """
  end
end
