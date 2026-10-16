defmodule Systems.Test.ModalLiveView do
  @moduledoc """
  Embedded LiveView for testing modal toolbar button functionality.
  Publishes toolbar buttons and handles toolbar events.
  """
  use CoreWeb, :embedded_live_view

  alias Systems.Test

  def dependencies(), do: [:title, :button_configs]

  def get_model(
        :not_mounted_at_router,
        %{"title" => title, "button_configs" => button_configs},
        _socket
      ) do
    %Test.ModalModel{
      id: :modal_test,
      title: title,
      button_configs: button_configs
    }
  end

  def get_model(:not_mounted_at_router, _session, _socket) do
    %Test.ModalModel{
      id: :modal_test,
      title: "Modal Test View",
      button_configs: []
    }
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, assign(socket, received_toolbar_events: [])}
  end

  @impl true
  def handle_view_model_updated(socket) do
    socket
    |> publish_toolbar_buttons()
  end

  defp publish_toolbar_buttons(%{assigns: %{vm: %{buttons: buttons}}} = socket) do
    publish_event(socket, {:update_modal_buttons, %{buttons: buttons}})
  end

  @impl true
  def handle_info({:modal_toolbar_event, event, item}, socket) do
    received = [{event, item} | socket.assigns.received_toolbar_events]
    {:noreply, assign(socket, received_toolbar_events: received)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="modal-embedded-view">
      <h2>{@vm.title}</h2>
      <div data-testid="received-toolbar-events">
        <%= for {event, item} <- @received_toolbar_events do %>
          <div class="toolbar-event" data-event={event}>{inspect({event, item})}</div>
        <% end %>
      </div>
    </div>
    """
  end
end
