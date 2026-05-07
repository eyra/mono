defmodule Systems.Test.EmbeddedLiveView do
  @moduledoc """
  Generic embedded LiveView for testing purposes.
  Can optionally render a nested child and publish events.
  """
  use CoreWeb, :embedded_live_view

  alias Systems.Test

  def dependencies(), do: [:vm]

  def get_model(:not_mounted_at_router, %{"vm" => vm}, _socket) do
    %Test.EmbeddedModel{
      id: vm.id,
      title: vm.title,
      items: vm.items
    }
  end

  def get_model(:not_mounted_at_router, _session, _socket) do
    %Test.EmbeddedModel{id: :default, title: "Default", items: [1, 2]}
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_view_model_updated(socket) do
    socket
  end

  @impl true
  def handle_event("select_item", %{"item_id" => item_id}, socket) do
    item_id = String.to_integer(item_id)
    changes = %{selected_item: item_id}

    event = %LiveNest.Event{
      name: :user_state_changed,
      source: {self(), socket.assigns.element_id},
      payload: changes
    }

    {:noreply, publish_event(socket, event)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid={"embedded-view-#{@vm.id}"}>
      <h2>{@vm.title}</h2>
      <%= for item_id <- @vm.items do %>
        <button phx-click="select_item" phx-value-item_id={item_id} data-testid={"item-#{item_id}"}>
          Select Item {item_id}
        </button>
      <% end %>
    </div>
    """
  end
end
