defmodule Systems.Org.PoolsView do
  @moduledoc """
  Embedded LiveView for the Pools tab on the Org page.

  Read-only list of pools currently linked to the organisation. Pool ↔ Org
  links are managed via `Pool.Assembly` / seeds today; an interactive linking
  UI will be added later via the API/CLI.
  """
  use CoreWeb, :embedded_live_view

  alias Frameworks.Pixel.Grid
  alias Frameworks.Pixel.Text
  alias Systems.Org

  import Org.ItemView

  def dependencies(), do: [:node_id, :locale]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{node_id: node_id}}) do
    Org.Public.get_node!(node_id)
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("card_clicked", %{"item" => pool_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/pool/#{pool_id}/content")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="org-pools-view">
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2>
          <%= dgettext("eyra-org", "pools.title") %> <span class="text-primary"><%= @vm.pool_count %></span>
        </Text.title2>
        <.spacing value="S" />

        <Grid.dynamic>
          <%= for pool <- @vm.pools do %>
            <div data-testid={"pool-item-#{pool.item}"}>
              <.item_view {pool} />
            </div>
          <% end %>
        </Grid.dynamic>
      </Area.content>
    </div>
    """
  end
end
