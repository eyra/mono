defmodule Systems.Project.ToolRefView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Frameworks.Concept

  alias Systems.{
    Project
  }

  def update(%{id: id, tool_ref: tool_ref, task: task}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        tool_ref: tool_ref,
        task: task
      )
      |> compose_child(:launcher)
    }
  end

  @impl true
  def compose(:launcher, %{tool_ref: tool_ref}) do
    Project.ToolRefModel.tool(tool_ref)
    |> Concept.ToolModel.launcher()
  end

  @impl true
  def handle_event("complete_task", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "complete_task")}
  end

  @impl true
  def handle_event("tool_initialized", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "tool_initialized")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full h-full">
      <%= if Fabric.get_child(@fabric, :launcher) do %>
        <.child name={:launcher} fabric={@fabric} />
      <% end %>
    </div>
    """
  end
end
