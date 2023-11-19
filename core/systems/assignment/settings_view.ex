defmodule Systems.Assignment.SettingsView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Systems.{
    Assignment
  }

  @impl true
  def update(%{id: id, entity: assignment, uri_origin: uri_origin}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: assignment,
        uri_origin: uri_origin
      )
      |> update_storage_connector()
      |> update_panel_connector()
    }
  end

  defp update_storage_connector(
         %{assigns: %{entity: assignment, uri_origin: uri_origin}} = socket
       ) do
    child =
      prepare_child(socket, :storage_connector, Assignment.ConnectorView, %{
        assignment: assignment,
        connection: assignment.storage_endpoint,
        type: :storage,
        uri_origin: uri_origin
      })

    show_child(socket, child)
  end

  defp update_panel_connector(%{assigns: %{entity: assignment, uri_origin: uri_origin}} = socket) do
    child =
      prepare_child(socket, :panel_connector, Assignment.ConnectorView, %{
        assignment: assignment,
        connection: assignment.external_panel,
        type: :panel,
        uri_origin: uri_origin
      })

    show_child(socket, child)
  end

  @impl true
  def handle_event("finish", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
        <Margin.y id={:page_top} />
        <Text.title2><%= dgettext("eyra-assignment", "settings.title") %></Text.title2>

        <Text.title3><%= dgettext("eyra-assignment", "settings.panel.title") %></Text.title3>
        <Text.body><%= dgettext("eyra-assignment", "settings.panel.body") %></Text.body>
        <.spacing value="M" />
        <.child id={:panel_connector} fabric={@fabric}/>
        <.spacing value="L" />

        <Text.title3><%= dgettext("eyra-assignment", "settings.data_storage.title") %></Text.title3>
        <Text.body><%= dgettext("eyra-assignment", "settings.data_storage.body") %></Text.body>
        <.spacing value="M" />
        <.child id={:storage_connector} fabric={@fabric}/>

      </Area.content>
    </div>
    """
  end
end
