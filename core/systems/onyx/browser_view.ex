defmodule Systems.Onyx.BrowserView do
  use Phoenix.LiveView
  use LiveNest, :embedded_live_view
  use CoreWeb.UI
  use Frameworks.Pixel

  use Gettext, backend: CoreWeb.Gettext

  import Frameworks.Pixel.FilterBar

  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.SearchBar

  alias Systems.Onyx

  @impl true
  def mount(
        :not_mounted_at_router,
        %{"model" => model, "entities" => entities, "history" => history},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        model: model,
        entities: entities,
        active_filters: [],
        history: history,
        query: [],
        query_string: ""
      )
      |> update_view_model()
      |> update_filter_selector()
      |> update_search_bar()
    }
  end

  defp update_view_model(%{assigns: %{model: model} = assigns} = socket) do
    assign(socket, :vm, Onyx.BrowserViewBuilder.view_model(model, assigns))
  end

  defp update_filter_selector(%{assigns: %{vm: %{filters: filters}}} = socket) do
    filter_selector =
      LiveNest.Element.prepare_live_component(
        :filter_selector,
        Selector,
        items: filters,
        type: :label
      )

    assign(socket, :filter_selector, filter_selector)
  end

  defp update_search_bar(%{assigns: %{query_string: query_string}} = socket) do
    search_bar =
      LiveNest.Element.prepare_live_component(
        :search_bar,
        SearchBar,
        query_string: query_string,
        placeholder: dgettext("eyra-onyx", "browser.search.placeholder"),
        debounce: "200"
      )

    assign(socket, :search_bar, search_bar)
  end

  @impl true
  def handle_event(
        "toggle-filter",
        %{"item" => item_id},
        %{assigns: %{active_filters: active_filters}} = socket
      ) do
    active_filters =
      if Enum.member?(active_filters, item_id) do
        List.delete(active_filters, item_id)
      else
        [item_id | active_filters]
      end

    {
      :noreply,
      socket
      |> assign(active_filters: active_filters)
      |> update_view_model()
    }
  end

  def handle_event(
        "card_clicked",
        %{"item" => item_id},
        %{assigns: %{vm: %{history_cards: history_cards, cards: cards}}} = socket
      ) do
    {event, payload} =
      case Enum.find(history_cards, &(&1.id == item_id)) do
        %{model: {module, id}} ->
          {:back_to_model, %{module: module, id: id}}

        _ ->
          case Enum.find(cards, &(&1.id == item_id)) do
            %{model: {module, id}} ->
              {:show_model, %{module: module, id: id}}

            nil ->
              raise "Card not found: #{item_id}"
          end
      end

    {
      :noreply,
      socket
      |> publish_event({event, payload})
    }
  end

  @impl true
  def consume_event(
        %{name: :search_query, payload: %{query: query, query_string: query_string}},
        socket
      ) do
    {
      :stop,
      socket
      |> assign(query: query, query_string: query_string)
      |> update_view_model()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />

        <%= if @vm.history_count > 0 do %>
          <Text.title2>
            <%= dgettext("eyra-onyx", "browser.history.title") %>
            <span class="text-primary"><%= @vm.history_count %></span>
          </Text.title2>
          <.spacing value="S" />
          <div class="flex flex-col gap-4 items-center w-full">
            <%= for card <- @vm.history_cards do %>
              <div class="w-full">
                <Onyx.CardView.dynamic card={card}/>
              </div>
            <% end %>
          </div>
          <.spacing value="L" />
        <% end %>
        <Text.title2>
          <%= dgettext("eyra-onyx", "browser.items.title") %>
          <span class="text-primary"><%= @vm.card_count %></span>
        </Text.title2>
        <div class="flex flex-row gap-4 items-center">
           <.filter_bar items={@vm.filters} />
          <div class="flex-grow" />
          <div class="flex-shrink-0">
            <.element {Map.from_struct(@search_bar)} socket={@socket} />
          </div>
        </div>
        <.spacing value="M" />
        <Grid.dynamic>
            <%= for card <- @vm.cards do %>
              <Onyx.CardView.dynamic card={card}/>
            <% end %>
        </Grid.dynamic>
      </Area.content>
    </div>
    """
  end
end
