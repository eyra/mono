defmodule Systems.Citizen.Overview do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Text.Title2
  alias Frameworks.Pixel.Selector.Selector
  alias CoreWeb.UI.ContentList

  alias Systems.{
    Citizen,
    Pool
  }

  prop(props, :map, required: true)

  data(pool, :map)
  data(citizens, :map)
  data(query, :any, default: nil)
  data(query_string, :string, default: "")
  data(filtered_citizens, :list)
  data(filtered_citizen_items, :list)
  data(filter_labels, :list)
  data(email_button, :map)

  # Handle Selector Update
  def update(%{active_item_ids: active_filters, selector_id: :citizen_filters}, socket) do
    {
      :ok,
      socket
      |> assign(active_filters: active_filters)
      |> prepare_citizens()
    }
  end

  # Handle Search Bar Update
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
  def update(%{props: %{citizens: citizens}} = _params, %{assigns: %{id: _id}} = socket) do
    {
      :ok,
      socket
      |> assign(citizens: citizens)
      |> prepare_citizens()
    }
  end

  # Initial update
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
    }
  end

  @impl true
  def handle_event("email", _, %{assigns: %{filtered_citizens: filtered_citizens}} = socket) do
    send(self(), {:email_dialog, %{recipients: filtered_citizens}})
    {:noreply, socket}
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
      |> Enum.map(&Pool.Builders.ParticipantItem.view_model(&1, socket))

    socket
    |> assign(
      filtered_citizens: filtered_citizens,
      filtered_citizen_items: filtered_citizen_items
    )
  end

  def render(assigns) do
    ~F"""
    <ContentArea>
      <MarginY id={:page_top} />
      <Empty
        :if={@citizens == []}
        title={dgettext("link-citizen", "citizens.empty.title")}
        body={dgettext("link-citizen", "citizens.empty.description")}
        illustration="members"
      />
      <div :if={not Enum.empty?(@citizens)}>
        <div class="flex flex-row gap-3 items-center">
          <div class="font-label text-label">Filter:</div>
          <Selector id={:citizen_filters} items={@filter_labels} parent={%{type: __MODULE__, id: @id}} />
          <div class="flex-grow" />
          <div class="flex-shrink-0">
            <SearchBar
              id={:citizen_search_bar}
              query_string={@query_string}
              placeholder={dgettext("link-citizen", "search.placeholder")}
              debounce="200"
              parent={%{type: __MODULE__, id: @id}}
            />
          </div>
        </div>
        <Spacing value="L" />
        <div class="flex flex-row">
          <Title2>{dgettext("link-citizen", "tabbar.item.citizens")} <span class="text-primary">{Enum.count(@filtered_citizens)}</span></Title2>
          <div class="flex-grow" />
          <DynamicButton vm={@email_button} />
        </div>
        <ContentList items={@filtered_citizen_items} />
      </div>
    </ContentArea>
    """
  end
end
