defmodule Fabric.TestLiveComponent do
  use Phoenix.LiveComponent
  use Fabric.LiveComponent

  @impl true
  def update(%{"id" => id}, socket) do
    {:ok, socket |> assign(id: id)}
  end

  @impl true
  def handle_event("event", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div />
    """
  end
end
