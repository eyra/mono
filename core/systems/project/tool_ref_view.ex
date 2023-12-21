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
      |> reset_fabric()
      |> update_launcher()
    }
  end

  def update_launcher(%{assigns: %{tool_ref: %{id: id} = tool_ref}} = socket) do
    %{module: module, params: params} =
      Project.ToolRefModel.tool(tool_ref)
      |> Concept.ToolModel.launcher()

    child = Fabric.prepare_child(socket, "tool_ref_#{id}", module, params)
    socket |> show_child(child)
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
      <.stack fabric={@fabric} />
    </div>
    """
  end
end
