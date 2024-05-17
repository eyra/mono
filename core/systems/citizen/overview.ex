defmodule Systems.Citizen.Overview do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Selector
  import Frameworks.Pixel.Content
  import Frameworks.Pixel.Empty

  alias Systems.{
    Citizen,
    Pool
  }

  # Handle Search Bar Update
  @impl true
  def update(%{search_bar: :citizen_search_bar, query_string: query_string, query: query}, socket) do
    {
      :ok,
      socket
      |> assign(
        query: query,
        query_string: query_string
      )
      |> prepare_citizens()
    }
  end

  # View model update
  @impl true
  def update(%{props: %{citizens: citizens}} = _params, %{assigns: %{id: _id}} = socket) do
    {
      :ok,
      socket
      |> assign(citizens: citizens)
      |> prepare_citizens()
    }
  end

  # Initial update
  @impl true
  def update(
        %{id: id, props: %{citizens: citizens, pool: pool}} = _params,
        %{assigns: %{myself: target}} = socket
      ) do
    filter_labels = Citizen.CriteriaFilters.labels([])

    email_button = %{
      action: %{type: :send, event: "email", target: target},
      face: %{type: :label, label: dgettext("eyra-ui", "notify.all"), icon: :chat}
    }

    {
      :ok,
      socket
      |> assign(
        id: id,
        citizens: citizens,
        pool: pool,
        active_filters: [],
        filter_labels: filter_labels,
        email_button: email_button
      )
      |> prepare_citizens()
      |> compose_child(:citizen_filters)
      |> compose_child(:citizen_search_bar)
    }
  end

  @impl true
  def compose(:citizen_filters, %{filter_labels: items}) do
    %{
      module: Selector,
      params: %{
        items: items,
        type: :label
      }
    }
  end

  @impl true
  def compose(:citizen_search_bar, %{query_string: query_string}) do
    %{
      module: SearchBar,
      params: %{
        query_string: query_string,
        placeholder: dgettext("link-citizen", "search.placeholder"),
        debounce: "200"
      }
    }
  end

  defp filter(citizens, nil), do: citizens
  defp filter(citizens, []), do: citizens

  defp filter(citizens, filters) do
    citizens
    |> Enum.filter(&Citizen.CriteriaFilters.include?(&1.features.gender, filters))
  end

  defp query(citizens, nil), do: citizens
  defp query(citizens, []), do: citizens

  defp query(citizens, query) when is_list(query) do
    citizens
    |> Enum.filter(&include?(&1, query))
  end

  defp include?(_citizen, []), do: true

  defp include?(citizen, [word]) do
    include?(citizen, word)
  end

  defp include?(citizen, [word | rest]) do
    include?(citizen, word) and include?(citizen, rest)
  end

  defp include?(_citizen, ""), do: true

  defp include?(citizen, word) when is_binary(word) do
    word = String.downcase(word)

    String.contains?(citizen.profile.fullname |> String.downcase(), word) or
      String.contains?(citizen.email |> String.downcase(), word)
  end

  defp prepare_citizens(
         %{
           assigns: %{
             citizens: citizens,
             active_filters: active_filters,
             query: query
           }
         } = socket
       ) do
    filtered_citizens =
      citizens
      |> filter(active_filters)
      |> query(query)

    filtered_citizen_items =
      filtered_citizens
      |> Enum.map(&Pool.ParticipantItemBuilder.view_model(&1, socket))

    socket
    |> assign(
      filtered_citizens: filtered_citizens,
      filtered_citizen_items: filtered_citizen_items
    )
  end

  # Events

  @impl true
  def handle_event("email", _, %{assigns: %{filtered_citizens: filtered_citizens}} = socket) do
    send(self(), {:email_dialog, %{recipients: filtered_citizens}})
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "active_item_ids",
        %{active_item_ids: active_filters, selector_id: :citizen_filters},
        socket
      ) do
    {
      :noreply,
      socket
      |> assign(active_filters: active_filters)
      |> prepare_citizens()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <%= if Enum.empty?(@citizens) do %>
        <.empty
          title={dgettext("link-citizen", "citizens.empty.title")}
          body={dgettext("link-citizen", "citizens.empty.description")}
          illustration="members"
        />
      <% else %>
        <div>
          <div class="flex flex-row gap-3 items-center">
            <div class="font-label text-label">Filter:</div>
            <.child name={:citizen_filters} fabric={@fabric} />
            <div class="flex-grow" />
            <div class="flex-shrink-0">
              <.child name={:citizen_search_bar} fabric={@fabric} />
            </div>
          </div>
          <.spacing value="L" />
          <div class="flex flex-row">
            <Text.title2><%= dgettext("link-citizen", "tabbar.item.citizens") %> <span class="text-primary"><%= Enum.count(@filtered_citizens) %></span></Text.title2>
            <div class="flex-grow" />
            <Button.dynamic {@email_button} />
          </div>
          <.list items={@filtered_citizen_items} />
        </div>
      <% end %>
      </Area.content>
    </div>
    """
  end
end
