defmodule Systems.Assignment.CrewTaskSingleView do
  use CoreWeb, :live_component
  use Systems.Assignment.CrewTaskHelpers

  # Make sure this name is unique, see: Systems.Assignment.CrewTaskListView
  @tool_ref_view_name :tool_ref_view_single

  @impl true
  def update(
        %{
          work_item: work_item,
          crew: crew,
          user: user,
          timezone: timezone,
          panel_info: panel_info,
          user_state_data: user_state_data
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        work_items: [work_item],
        selected_item: work_item,
        crew: crew,
        user: user,
        timezone: timezone,
        panel_info: panel_info,
        user_state_data: user_state_data,
        tool_ref_view_name: @tool_ref_view_name
      )
      |> update_participant()
      |> update_launcher()
      |> compose_child(@tool_ref_view_name)
      |> start_task()
    }
  end

  defp update_launcher(%{assigns: %{selected_item: selected_item}} = socket) do
    launcher = launcher(selected_item)
    socket |> assign(launcher: launcher)
  end

  # Behaviours

  @impl true
  def handle_tool_exited(socket) do
    socket |> handle_task_completed()
  end

  @impl true
  def handle_tool_initialized(socket) do
    socket |> send_event(@tool_ref_view_name, "tool_initialized")
  end

  # Compose

  @impl true
  def compose(
        @tool_ref_view_name,
        %{
          user: user,
          participant: participant,
          timezone: timezone,
          user_state_data: user_state_data,
          selected_item: {%{title: title, tool_ref: tool_ref}, task} = selected_item
        }
      ) do
    icon = get_icon(selected_item)

    %{
      module: Workflow.ToolRefView,
      params: %{
        title: title,
        icon: icon,
        tool_ref: tool_ref,
        task: task,
        visible: true,
        user: user,
        participant: participant,
        timezone: timezone,
        user_state_data: user_state_data
      }
    }
  end

  def compose(@tool_ref_view_name, _) do
    nil
  end

  # Events

  def handle_event("tool_initialized", payload, socket) do
    {:noreply, socket |> send_event(@tool_ref_view_name, "tool_initialized", payload)}
  end

  def handle_event("complete_task", _, socket) do
    {:noreply, socket |> handle_task_completed()}
  end

  # Private

  @impl true
  def render(assigns) do
    ~H"""
      <div id="crew_task_single_view" class="w-full h-full p-4 sm:p-8" >
        <.child name={@tool_ref_view_name} fabric={@fabric} />
      </div>
    """
  end
end
