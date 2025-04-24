defmodule Systems.Workflow.ToolRefView do
  use CoreWeb, :live_component

  require Logger

  alias Frameworks.Concept
  alias Systems.Workflow

  def update(
        %{
          id: id,
          title: title,
          icon: icon,
          tool_ref: tool_ref,
          task: task,
          visible: visible,
          user: user,
          participant: participant,
          timezone: timezone,
          user_state_data: user_state_data
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        title: title,
        icon: icon,
        tool_ref: tool_ref,
        task: task,
        visible: visible,
        user: user,
        participant: participant,
        timezone: timezone,
        user_state_data: user_state_data
      )
      |> reset_fabric()
      |> update_tool_ref_name()
      |> update_launcher()
    }
  end

  def update_tool_ref_name(%{assigns: %{tool_ref: %{id: id}}} = socket) do
    socket |> assign(tool_ref_name: "tool_ref_#{id}")
  end

  def update_launcher(%{assigns: %{tool_ref: tool_ref}} = socket) do
    launcher =
      tool_ref
      |> Workflow.ToolRefModel.tool()
      |> Concept.ToolModel.launcher()

    socket |> update_launcher(launcher)
  end

  def update_launcher(
        %{
          assigns: %{
            tool_ref_name: tool_ref_name,
            user: user,
            participant: participant,
            timezone: timezone,
            title: title,
            icon: icon,
            visible: visible,
            user_state_data: user_state_data
          }
        } = socket,
        %{module: module, params: params}
      ) do
    params =
      Map.merge(params, %{
        user: user,
        participant: participant,
        timezone: timezone,
        title: title,
        icon: icon,
        visible: visible,
        user_state_data: user_state_data
      })

    child = Fabric.prepare_child(socket, tool_ref_name, module, params)
    socket |> show_child(child)
  end

  def update_launcher(socket, _) do
    # This use case is supported for preview mode
    tool_ref = Map.get(socket.assigns, :tool_ref)
    Logger.warning("No module launcher found for #{inspect(tool_ref)}")
    socket
  end

  @impl true
  def handle_event("hide_modal", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "hide_modal")}
  end

  @impl true
  def handle_event("complete_task", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "complete_task")}
  end

  @impl true
  def handle_event("cancel_task", _payload, socket) do
    {:noreply, socket |> send_event(:parent, "cancel_task")}
  end

  @impl true
  def handle_event(
        "tool_initialized",
        _payload,
        %{assigns: %{tool_ref_name: tool_ref_name}} = socket
      ) do
    {:noreply, socket |> send_event(tool_ref_name, "tool_initialized")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="tool-ref-view w-full h-full">
      <.child name={@tool_ref_name} fabric={@fabric} />
    </div>
    """
  end
end
