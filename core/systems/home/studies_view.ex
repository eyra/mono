defmodule Systems.Home.StudiesView do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Text
  alias Systems.Advert

  # Subsequent view model updates: keep filter/search state
  @impl true
  def update(%{items: items, years: years}, %{assigns: %{active_year: active_year}} = socket) do
    {
      :ok,
      socket
      |> assign(items: items, years: years, active_year: active_year || List.first(years))
      |> apply_filter()
    }
  end

  # Initial update
  @impl true
  def update(%{items: items, years: years}, socket) do
    {
      :ok,
      socket
      |> assign(
        items: items,
        years: years,
        active_year: List.first(years),
        query: nil,
        query_string: ""
      )
      |> compose_child(:studies_search_bar)
      |> apply_filter()
    }
  end

  @impl true
  def compose(:studies_search_bar, %{query_string: query_string}) do
    %{
      module: SearchBar,
      params: %{
        query_string: query_string,
        placeholder: dgettext("eyra-home", "studies.search.placeholder"),
        debounce: "200"
      }
    }
  end

  @impl true
  def handle_event(
        "search_query",
        %{query: query, query_string: query_string, source: %{name: :studies_search_bar}},
        socket
      ) do
    {
      :noreply,
      socket
      |> assign(query: query, query_string: query_string)
      |> apply_filter()
    }
  end

  @impl true
  def handle_event("select_year", %{"year" => year}, socket) do
    {
      :noreply,
      socket
      |> assign(active_year: String.to_integer(year))
      |> apply_filter()
    }
  end

  @impl true
  def handle_event(
        "card_clicked",
        %{"item" => card_id},
        %{assigns: %{filtered_cards: cards}} = socket
      ) do
    card_id = String.to_integer(card_id)
    %{path: path} = Enum.find(cards, &(&1.id == card_id))
    {:noreply, push_navigate(socket, to: path)}
  end

  defp apply_filter(%{assigns: %{items: items, active_year: active_year, query: query}} = socket) do
    filtered_cards =
      items
      |> filter_by_year(active_year)
      |> filter_by_query(query)
      |> Enum.map(& &1.card)

    assign(socket, filtered_cards: filtered_cards)
  end

  defp filter_by_year(items, nil), do: items
  defp filter_by_year(items, year), do: Enum.filter(items, &(&1.year == year))

  defp filter_by_query(items, nil), do: items
  defp filter_by_query(items, []), do: items

  defp filter_by_query(items, query) when is_list(query) do
    Enum.filter(items, &match_query?(&1, query))
  end

  defp match_query?(item, query) do
    Enum.all?(query, &match_word?(item, &1))
  end

  defp match_word?(%{card: %{title: title}}, word) do
    String.contains?(String.downcase(title), String.downcase(word))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="studies-marketplace">
      <%= if Enum.empty?(@items) do %>
        <Text.body><%= dgettext("eyra-home", "studies.empty.message") %></Text.body>
      <% else %>
        <div class="flex flex-row items-center gap-3">
          <div class="font-label text-label">Filter:</div>
          <%= for year <- @years do %>
            <div
              class="cursor-pointer select-none"
              phx-click="select_year"
              phx-value-year={year}
              phx-target={@myself}
            >
              <div class={[
                "rounded-full px-6 py-3 text-label font-label select-none",
                year == @active_year && "bg-primary text-white",
                year != @active_year && "bg-grey5 text-grey2"
              ]}>
                <%= year %>
              </div>
            </div>
          <% end %>
          <div class="flex-grow" />
          <div class="flex-shrink-0">
            <.child name={:studies_search_bar} fabric={@fabric} />
          </div>
        </div>
        <.spacing value="L" />
        <Grid.dynamic>
          <%= for card <- @filtered_cards do %>
            <Advert.CardView.dynamic card={card} target={@myself} />
          <% end %>
        </Grid.dynamic>
      <% end %>
    </div>
    """
  end
end
