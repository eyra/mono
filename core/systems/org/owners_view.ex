defmodule Systems.Org.OwnersView do
  use CoreWeb, :embedded_live_view

  alias Frameworks.Pixel.Text
  alias Systems.Org

  def dependencies(), do: [:node_id]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{node_id: node_id}}) do
    Org.Public.get_node!(node_id, Org.NodeModel.preload_graph(:full))
  end

  def get_model(:not_mounted_at_router, %{"node_id" => node_id}, _socket) do
    Org.Public.get_node!(node_id, Org.NodeModel.preload_graph(:full))
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <Text.title2><%= dgettext("eyra-org", "owners.title") %></Text.title2>
      <.spacing value="M" />

      <%= if Enum.empty?(@vm.owners) do %>
        <Text.body><%= dgettext("eyra-org", "owners.empty") %></Text.body>
      <% else %>
        <div class="flex flex-col gap-4">
          <%= for owner <- @vm.owners do %>
            <div class="flex flex-row items-center gap-4 p-4 bg-grey6 rounded-lg">
              <div class="flex-grow">
                <Text.body_medium><%= owner.displayname %></Text.body_medium>
                <Text.body><%= owner.email %></Text.body>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
      </Area.content>
    </div>
    """
  end
end
