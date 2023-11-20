defmodule Systems.Assignment.ConnectorView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Systems.{
    Assignment
  }

  @impl true
  def update(
        %{
          id: id,
          type: type,
          assignment: assignment,
          connection: connection,
          uri_origin: uri_origin
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        type: type,
        assignment: assignment,
        connection: connection,
        uri_origin: uri_origin
      )
      |> update_connect_button()
      |> update_connection_view()
    }
  end

  defp update_connect_button(%{assigns: %{myself: myself}} = socket) do
    connect_button = %{
      action: %{type: :send, target: myself, event: "connect"},
      face: %{type: :primary, label: dgettext("eyra-assignment", "connect.button")}
    }

    assign(socket, connect_button: connect_button)
  end

  defp update_connection_view(%{assigns: %{connection: nil}} = socket) do
    assign(socket, connection_view: nil)
  end

  defp update_connection_view(
         %{
           assigns: %{
             id: id,
             type: type,
             connection: connection,
             assignment: assignment,
             uri_origin: uri_origin
           }
         } = socket
       ) do
    child =
      prepare_child(socket, "#{id}_connection_view", Assignment.ConnectionView, %{
        assignment: assignment,
        connection: connection,
        type: type,
        uri_origin: uri_origin
      })

    show_child(socket, child)
  end

  @impl true
  def handle_event(
        "connect",
        _payload,
        %{assigns: %{type: type, assignment: assignment}} = socket
      ) do
    module = Assignment.Private.connector_popup_module(type)

    child =
      prepare_child(socket, :connector_popup, module, %{
        entity: assignment
      })

    show_popup(socket, child)
    {:noreply, socket}
  end

  @impl true
  def handle_event("edit", _payload, %{assigns: %{type: type, assignment: assignment}} = socket) do
    module = Assignment.Private.connector_popup_module(type)

    child =
      prepare_child(socket, :connector_popup, module, %{
        entity: assignment
      })

    show_popup(socket, child)
    {:noreply, socket}
  end

  @impl true
  def handle_event("finish", %{source: %{id: :connector_popup}, connection: _connection}, socket) do
    hide_popup(socket, :connector_popup)
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel", %{source: %{id: :connector_popup}}, socket) do
    hide_popup(socket, :connector_popup)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
    <%= if get_child(@fabric, "#{@id}_connection_view") do %>
      <.child id={"#{@id}_connection_view"} fabric={@fabric}/>
    <% else %>
      <.wrap>
        <Button.dynamic {@connect_button} />
      </.wrap>
    <% end %>
    </div>
    """
  end
end
