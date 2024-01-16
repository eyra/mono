defmodule Systems.Project.ToolRefView do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Frameworks.Concept

  alias Systems.{
    Project
  }

  def update(%{id: id, title: title, tool_ref: tool_ref, task: task, visible: visible}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        tool_ref: tool_ref,
        task: task,
        visible: visible
      )
      |> reset_fabric()
      |> update_launcher()
    }
  end

  def update_launcher(%{assigns: %{tool_ref: tool_ref}} = socket) do
    launcher =
      tool_ref
      |> Project.ToolRefModel.tool()
      |> Concept.ToolModel.launcher()

    socket |> update_launcher(launcher)
  end

  def update_launcher(
        %{assigns: %{tool_ref: %{id: id}, title: title, visible: visible}} = socket,
        %{module: module, params: params}
      ) do
    params = Map.merge(params, %{title: title, visible: visible})
    child = Fabric.prepare_child(socket, "tool_ref_#{id}", module, params)
    socket |> show_child(child)
  end

  def update_launcher(socket, nil) do
    # This use case is supported for preview mode
    tool_ref = Map.get(socket.assigns, :tool_ref)
    Logger.warning("No launcher found for #{inspect(tool_ref)}")
    socket
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
