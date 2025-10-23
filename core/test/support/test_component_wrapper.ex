defmodule CoreWeb.TestComponentWrapper do
  @moduledoc """
  A simple wrapper LiveView for testing LiveComponents in isolation.
  """
  use Phoenix.LiveView
  use LiveNest, :embedded_live_view

  @impl true
  def mount(_params, session, socket) do
    component_module = Map.get(session, "component_module")
    component_id = Map.get(session, "component_id", "test_component")
    component_assigns = Map.get(session, "component_assigns", %{})

    {:ok,
     socket
     |> assign(:component_module, component_module)
     |> assign(:component_id, component_id)
     |> assign(:component_assigns, component_assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div data-testid="test-wrapper">
      <.live_component
        module={@component_module}
        id={@component_id}
        {@component_assigns}
      />
    </div>
    """
  end

  @impl true
  def handle_info({:update_component, updates}, socket) do
    {:noreply,
     socket
     |> update(:component_assigns, fn assigns -> Map.merge(assigns, updates) end)}
  end
end
