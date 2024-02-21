defmodule Systems.Assignment.ConnectionView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Frameworks.Pixel.Panel

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
      |> update_title()
      |> update_buttons()
      |> update_special_view()
    }
  end

  defp update_title(%{assigns: %{type: type, assignment: assignment}} = socket) do
    title = Assignment.Private.connection_title(type, assignment)
    assign(socket, title: title)
  end

  defp update_buttons(%{assigns: %{myself: myself}} = socket) do
    disconnect_button = %{
      action: %{type: :send, target: myself, event: "disconnect"},
      face: %{
        type: :label,
        icon: :disconnect_tertiary,
        height: "h-4",
        text_color: "text-tertiary",
        label: dgettext("eyra-assignment", "disconnect.button")
      }
    }

    edit_button = %{
      action: %{type: :send, target: myself, event: "edit"},
      face: %{
        type: :label,
        icon: :edit_tertiary,
        height: "h-4",
        text_color: "text-tertiary",
        label: dgettext("eyra-ui", "edit.button")
      }
    }

    assign(socket, buttons: [edit_button, disconnect_button])
  end

  defp update_special_view(
         %{
           assigns: %{
             id: id,
             type: type,
             assignment: assignment,
             myself: myself,
             uri_origin: uri_origin
           }
         } = socket
       ) do
    special_view = %{
      id: "#{id}_connection_#{type}",
      module: Assignment.Private.connection_view_module(type),
      assignment: assignment,
      uri_origin: uri_origin,
      parent: myself
    }

    assign(socket, special_view: special_view)
  end

  @impl true
  def handle_event(
        "disconnect",
        _payload,
        %{assigns: %{special_view: %{id: id, module: module}}} = socket
      ) do
    send_update(module, id: id, event: :disconnect)
    {:noreply, socket}
  end

  @impl true
  def handle_event("edit", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "edit")}
  end

  @impl true
  def handle_event("change", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"#{@id}_connection"}>
      <Panel.flat bg_color="bg-grey1">
        <:title>
          <div class="flex flex-row gap-4 items-center">
            <div class="text-title3 font-title3 text-white">
              <%= @title %>
            </div>
            <div class="flex-grow" />
            <%= for button <- @buttons do %>
              <Button.dynamic {button} />
            <% end %>
          </div>
        </:title>
        <.live_component {@special_view} />
      </Panel.flat>
    </div>
    """
  end
end
