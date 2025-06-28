defmodule Fabric.LiveViewMock do
  use Phoenix.LiveView, layout: {Fabric.TestLayouts, :live}
  use Fabric.LiveView
  CoreWeb.Layouts

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {
      :ok,
      socket
      |> Fabric.new_fabric()
      |> add_child(:child_a, "Child A")
      |> add_child(:child_b, "Child B")
    }
  end

  def add_child(socket, child_id, text) when is_binary(text) do
    socket
    |> add_child(child_id, %{
      module: Fabric.LiveComponentMock,
      params: %{
        text: text
      }
    })
  end

  @impl true
  def handle_event("event", _payload, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <.child name={:child_a} fabric={@fabric} />
      <.child name={:child_b} fabric={@fabric} />
    """
  end
end
