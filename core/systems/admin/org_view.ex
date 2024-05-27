defmodule Systems.Admin.OrgView do
  use CoreWeb, :live_component

  alias CoreWeb.Router.Helpers, as: Routes
  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Grid

  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Selector

  alias Systems.{
    Org,
    Content
  }

  import Org.ItemView

  # Handle Search Bar Update
  @impl true
  def update(%{search_bar: :org_search_bar, query_string: query_string, query: query}, socket) do
    {
      :ok,
      socket
      |> assign(
        query: query,
        query_string: query_string
      )
      |> prepare_organisations()
      |> compose_child(:org_filters)
    }
  end

  # Initial update
  @impl true
  def update(%{id: id, locale: locale}, socket) do
    filter_labels = Org.Types.labels([])

    organisations = Org.Public.list_nodes(Org.NodeModel.preload_graph(:full))

    {
      :ok,
      socket
      |> assign(
        id: id,
        filter_labels: filter_labels,
        organisations: organisations,
        locale: locale,
        active_filters: [],
        query: nil,
        query_string: ""
      )
      |> prepare_organisations()
      |> compose_child(:org_filters)
      |> compose_child(:org_search_bar)
    }
  end

  @impl true
  def compose(:org_filters, %{filter_labels: items}) do
    %{
      module: Selector,
      params: %{
        items: items,
        type: :label
      }
    }
  end

  @impl true
  def compose(:org_search_bar, %{query_string: query_string}) do
    %{
      module: SearchBar,
      params: %{
        query_string: query_string,
        placeholder: dgettext("eyra-org", "search.placeholder"),
        debounce: "200"
      }
    }
  end

  defp prepare_organisations(
         %{
           assigns: %{
             organisations: organisations,
             active_filters: active_filters,
             query: query,
             locale: locale
           }
         } = socket
       ) do
    filtered_organisations =
      organisations
      |> Org.Types.filter(active_filters)
      |> Enum.map(&view_model(&1, locale))
      |> query(query)

    socket
    |> assign(filtered_organisations: filtered_organisations)
  end

  def query(organisations, nil), do: organisations
  def query(organisations, []), do: organisations

  def query(organisations, query) when is_list(query) do
    organisations
    |> Enum.filter(&include?(&1, query))
  end

  def include?(_organisation, []), do: true

  def include?(organisation, [word]) do
    include?(organisation, word)
  end

  def include?(organisation, [word | rest]) do
    include?(organisation, word) and include?(organisation, rest)
  end

  def include?(_organisation, ""), do: true

  def include?(organisation, word) when is_binary(word) do
    word = String.downcase(word)

    String.contains?(organisation.title |> String.downcase(), word) or
      String.contains?(organisation.description |> String.downcase(), word)
  end

  defp view_model(%Org.NodeModel{id: id} = org, locale) do
    %{
      item: id,
      title: title(org, locale),
      description: description(org),
      tags: tags(org)
    }
  end

  defp title(%{full_name_bundle: full_name_bundle}, locale) do
    Content.TextBundleModel.text(full_name_bundle, locale)
  end

  defp tags(%{domains: nil}), do: []
  defp tags(%{domains: domains}), do: domains

  defp description(org) do
    [
      members_label(org),
      admins_label(org)
    ]
    |> Enum.filter(&(not is_nil(&1)))
    |> Enum.join("  |  ")
  end

  defp members_label(%{users: users}) do
    "#{dgettext("eyra-org", "org.members.label")}: #{Enum.count(users)}"
  end

  defp admins_label(_) do
    "#{dgettext("eyra-org", "org.admins.label")}: 0"
  end

  @impl true
  def handle_event("handle_item_click", %{"item" => org_id}, socket) do
    path = Routes.live_path(socket, Systems.Org.ContentPage, org_id)
    {:noreply, push_redirect(socket, to: path)}
  end

  @impl true
  def handle_event("create_org", _, socket) do
    timestamp = Timestamp.now() |> DateTime.to_unix()

    {:ok, %{org: %{id: org_id}}} =
      Org.Public.create_node(
        :university,
        ["org", "#{timestamp}"],
        [{:en, "Abbreviation"}, {:nl, "Afkorting"}],
        [{:en, "Name"}, {:nl, "Naam"}]
      )

    {
      :noreply,
      socket
      |> push_redirect(to: Routes.live_path(socket, Org.ContentPage, org_id))
    }
  end

  @impl true
  def handle_event(
        "active_item_ids",
        %{active_item_ids: active_filters, source: %{name: :org_filters}},
        socket
      ) do
    {
      :noreply,
      socket
      |> assign(active_filters: active_filters)
      |> prepare_organisations()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <div class="flex flex-row gap-3 items-center">
        <div class="font-label text-label">Filter:</div>
          <.child name={:org_filters} fabric={@fabric} />
        <div class="flex-grow" />
        <div class="flex-shrink-0">
          <.child name={:org_search_bar} fabric={@fabric} />
        </div>
      </div>
      <.spacing value="L" />

      <div class="flex flex-row items-center justify-center mb-6 md:mb-8 lg:mb-10">
        <div class="h-full">
          <Text.title2 margin=""><%= dgettext("eyra-admin", "org.content.title") %></Text.title2>
        </div>
        <div class="flex-grow">
        </div>
        <div class="h-full pt-2px lg:pt-1">
          <Button.Action.send event="create_org" target={@myself}>
            <div class="sm:hidden">
              <Button.Face.plain_icon label={dgettext("eyra-admin", "create.org.button.short")} icon={:forward} />
            </div>
            <div class="hidden sm:block">
              <Button.Face.plain_icon label={dgettext("eyra-admin", "create.org.button")} icon={:forward} />
            </div>
          </Button.Action.send>
        </div>
      </div>

      <Grid.dynamic>
        <%= for organisation <- @filtered_organisations do %>
          <div>
            <.item_view {organisation} target={@myself} />
          </div>
        <% end %>
      </Grid.dynamic>
      <.spacing value="XL" />
      </Area.content>
    </div>
    """
  end
end
