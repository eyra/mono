defmodule Fabric.LiveComponentMock do
  @moduledoc false
  use Fabric.LiveComponent

  @impl true
  def update(%{text: text}, socket) do
    {:ok, assign(socket, text: text)}
  end

  @impl true
  def handle_event("event", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div><%= @text %></div>
    """
  end
end
