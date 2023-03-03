defmodule Systems.Admin.OrgView do
  use CoreWeb.UI.LiveComponent

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.Text.Title2
  alias Frameworks.Pixel.Grid.DynamicGrid

  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Button.Face.PlainIcon
  alias Frameworks.Pixel.Button.Action.Send
  alias Frameworks.Pixel.Selector.Selector

  alias Systems.{
    Org,
    Content
  }

  prop(props, :any)

  data(locale, :string)
  data(organisations, :list)
  data(query, :any, default: nil)
  data(query_string, :string, default: "")
  data(filtered_organisations, :list)
  data(filter_labels, :list)
  data(active_filters, :list, default: [])

  # Handle Selector Update
  def update(%{active_item_ids: active_filters, selector_id: :org_filters}, socket) do
    {
      :ok,
      socket
      |> assign(active_filters: active_filters)
      |> prepare_organisations()
    }
  end

  # Handle Search Bar Update
  def update(%{search_bar: :org_search_bar, query_string: query_string, query: query}, socket) do
    {
      :ok,
      socket
      |> assign(
        query: query,
        query_string: query_string
      )
      |> prepare_organisations()
    }
  end

  # Initial update

  def update(%{id: id, props: %{locale: locale}}, socket) do
    filter_labels = Org.Types.labels([])

    organisations = Org.Public.list_nodes(Org.NodeModel.preload_graph(:full))

    {
      :ok,
      socket
      |> assign(
        id: id,
        filter_labels: filter_labels,
        organisations: organisations,
        locale: locale
      )
      |> prepare_organisations()
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

  def handle_event("handle_item_click", %{"item" => org_id}, socket) do
    path = Routes.live_path(socket, Systems.Org.ContentPage, org_id)
    {:noreply, push_redirect(socket, to: path)}
  end

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

  def render(assigns) do
    ~F"""
    <ContentArea>
      <MarginY id={:page_top} />
      <div class="flex flex-row gap-3 items-center">
        <div class="font-label text-label">Filter:</div>
        <Selector id={:org_filters} items={@filter_labels} parent={%{type: __MODULE__, id: @id}} />
        <div class="flex-grow" />
        <div class="flex-shrink-0">
          <SearchBar
            id={:org_search_bar}
            query_string={@query_string}
            placeholder={dgettext("eyra-org", "search.placeholder")}
            debounce="200"
            parent={%{type: __MODULE__, id: @id}}
          />
        </div>
      </div>
      <Spacing value="L" />

      <div class="flex flex-row items-center justify-center mb-6 md:mb-8 lg:mb-10">
        <div class="h-full">
          <Title2 margin="">{dgettext("eyra-admin", "org.content.title")}</Title2>
        </div>
        <div class="flex-grow">
        </div>
        <div class="h-full pt-2px lg:pt-1">
          <Send vm={%{event: "create_org", target: @myself}}>
            <div class="sm:hidden">
              <PlainIcon vm={label: dgettext("eyra-admin", "create.org.button.short"), icon: :forward} />
            </div>
            <div class="hidden sm:block">
              <PlainIcon vm={label: dgettext("eyra-admin", "create.org.button"), icon: :forward} />
            </div>
          </Send>
        </div>
      </div>

      <DynamicGrid>
        <div :for={organisation <- @filtered_organisations}>
          <Org.ItemView {...organisation} target={@myself} />
        </div>
      </DynamicGrid>
      <Spacing value="XL" />
    </ContentArea>
    """
  end
end
