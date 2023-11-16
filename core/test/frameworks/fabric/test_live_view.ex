defmodule Fabric.TestLiveView do
  use Phoenix.LiveView
  use Fabric.LiveView

  @impl true
  def mount(%{"id" => id}, _session, socket) do
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
