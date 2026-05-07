defmodule Systems.Assignment.ConnectorView do
  use CoreWeb, :live_component

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
      |> compose_child(:connection_view)
    }
  end

  defp update_connect_button(%{assigns: %{myself: myself}} = socket) do
    connect_button = %{
      action: %{type: :send, target: myself, event: "connect"},
      face: %{type: :primary, label: dgettext("eyra-assignment", "connect.button")}
    }

    assign(socket, connect_button: connect_button)
  end

  @impl true
  def compose(:connection_view, %{connection: nil}) do
    nil
  end

  @impl true
  def compose(:connection_view, %{
        type: type,
        connection: connection,
        assignment: assignment,
        uri_origin: uri_origin
      }) do
    %{
      module: Assignment.ConnectionView,
      params: %{
        assignment: assignment,
        connection: connection,
        type: type,
        uri_origin: uri_origin
      }
    }
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

    {:noreply, socket |> show_modal(child, :compact)}
  end

  @impl true
  def handle_event("edit", _payload, %{assigns: %{type: type, assignment: assignment}} = socket) do
    module = Assignment.Private.connector_popup_module(type)

    child =
      prepare_child(socket, :connector_popup, module, %{
        entity: assignment
      })

    {:noreply, socket |> show_modal(child, :compact)}
  end

  @impl true
  def handle_event(
        "finish",
        %{source: %{name: :connector_popup}, connection: _connection},
        socket
      ) do
    {:noreply, socket |> hide_modal(:connector_popup)}
  end

  @impl true
  def handle_event("cancel", %{source: %{name: :connector_popup}}, socket) do
    {:noreply, socket |> hide_modal(:connector_popup)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
    <%= if get_child(@fabric, :connection_view) do %>
      <.stack fabric={@fabric}/>
    <% else %>
      <.wrap>
        <Button.dynamic {@connect_button} />
      </.wrap>
    <% end %>
    </div>
    """
  end
end
