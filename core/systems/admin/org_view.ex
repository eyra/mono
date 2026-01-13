defmodule Systems.Admin.OrgView do
  use CoreWeb, :embedded_live_view

  alias CoreWeb.UI.Timestamp
  alias Frameworks.Pixel.AlertBanner
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text

  alias Systems.Admin
  alias Systems.Observatory
  alias Systems.Org

  import Org.ItemView

  def dependencies(), do: [:current_user, :locale, :is_admin?, :governable_orgs]

  def get_model(:not_mounted_at_router, _session, _assigns) do
    Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, assign(socket, query_string: "", active_filters: [])}
  end

  @impl true
  def handle_event("handle_item_click", %{"item" => org_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/org/node/#{org_id}")}
  end

  @impl true
  def handle_event("card_clicked", %{"item" => org_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/org/node/#{org_id}")}
  end

  @impl true
  def handle_event("create_org", _, socket) do
    timestamp = Timestamp.now() |> DateTime.to_unix()

    {:ok, %{org: %{id: org_id}}} =
      Org.Public.create_node(
        ["org", "#{timestamp}"],
        [{:en, "Abbreviation"}],
        [{:en, "Name"}]
      )

    {
      :noreply,
      socket
      |> push_navigate(to: ~p"/org/node/#{org_id}")
    }
  end

  @impl true
  def handle_event("show_archived", _, %{assigns: %{locale: locale}} = socket) do
    modal = Admin.OrgViewBuilder.build_archived_orgs_modal(locale)
    {:noreply, socket |> present_modal(modal)}
  end

  @impl true
  def handle_event("archive_org", %{"item" => org_id_string}, socket) do
    org_id = String.to_integer(org_id_string)
    org = Org.Public.get_node!(org_id)
    {:ok, _} = Org.Public.archive(org)

    {:noreply, update_view_model(socket)}
  end

  @impl true
  def handle_event(
        "setup_admins",
        %{"item" => org_id_string},
        %{assigns: %{locale: locale}} = socket
      ) do
    org_id = String.to_integer(org_id_string)
    org = Org.Public.get_node!(org_id, Org.NodeModel.preload_graph(:full))
    org_name = Systems.Content.TextBundleModel.text(org.full_name_bundle, locale)
    modal = Admin.OrgViewBuilder.build_admins_modal(org_id, org_name)
    {:noreply, socket |> present_modal(modal)}
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
  def consume_event(
        %{name: :active_item_ids, payload: %{active_item_ids: active_filters}},
        socket
      ) do
    {
      :stop,
      socket
      |> assign(active_filters: active_filters)
      |> update_view_model()
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="org-view">
      <Area.content>
      <Margin.y id={:page_top} />

      <%= for banner <- @vm.next_action_banners do %>
        <AlertBanner.action {banner} />
        <.spacing value="M" />
      <% end %>

      <div class="flex flex-row items-center justify-center mb-6 md:mb-8 lg:mb-10">
        <div class="h-full">
          <Text.title2 margin="" data-testid="org-title"><%= @vm.title %> <span class="text-primary"><%= @vm.org_count %></span></Text.title2>
        </div>
        <div class="flex-grow">
        </div>
        <%= if @vm.create_button do %>
          <div class="h-full pt-2px lg:pt-1">
            <Button.Action.send event={@vm.create_button.action.event}>
              <div class="sm:hidden">
                <Button.Face.plain_icon label={@vm.create_button.face_short.label} icon={@vm.create_button.face_short.icon} />
              </div>
              <div class="hidden sm:block">
                <Button.Face.plain_icon label={@vm.create_button.face.label} icon={@vm.create_button.face.icon} />
              </div>
            </Button.Action.send>
          </div>
        <% end %>
      </div>

      <%= if @vm.show_search_filter? do %>
        <div class="flex flex-row gap-3 items-center">
          <div class="font-label text-label"><%= dgettext("eyra-org", "filter.label") %></div>
          <.live_component
            module={Selector}
            id={:org_filters}
            items={@vm.filter_labels}
            type={:label}
          />
          <div class="flex-grow" />
          <div class="flex-shrink-0">
            <.live_component
              module={SearchBar}
              id={:org_search_bar}
              query_string={@query_string}
              placeholder={@vm.search_placeholder}
              debounce="200"
            />
          </div>
        </div>
        <.spacing value="L" />
      <% end %>

      <Grid.dynamic>
        <%= for organisation <- @vm.organisations do %>
          <div data-testid="org-item">
            <.item_view {organisation} />
          </div>
        <% end %>
      </Grid.dynamic>
      <.spacing value="L" />
      <%= if @vm.show_archived_button do %>
        <div class="flex justify-start">
          <Button.dynamic {@vm.show_archived_button} />
        </div>
      <% end %>
      <.spacing value="XL" />
      </Area.content>
    </div>
    """
  end
end
