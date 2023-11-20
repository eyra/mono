defmodule Fabric.LiveViewMock do
  use Fabric.LiveView, Fabric.TestLayouts

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {
      :ok,
      socket
      |> add_child(:child_a, "Child A")
      |> add_child(:child_b, "Child B")
    }
  end

  defp add_child(socket, child_id, text) do
    child = prepare_child(socket, child_id, Fabric.LiveComponentMock, %{text: text})
    socket |> show_child(child)
  end

  @impl true
  def handle_event("event", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <.child id={:child_a} fabric={@fabric} />
      <.child id={:child_b} fabric={@fabric} />
    """
  end
end
