defmodule Systems.Assignment.CrewTaskListView do
  use CoreWeb, :live_component
  use Systems.Assignment.CrewTaskHelpers

  alias Frameworks.Utility.UserState
  alias Systems.Assignment

  # Make sure this name is unique, see: Systems.Assignment.CrewTaskSingleView
  @tool_ref_view_name :tool_ref_view_list

  @impl true
  def update(
        %{
          work_items: work_items,
          crew: crew,
          user: user,
          timezone: timezone,
          panel_info: panel_info,
          user_state_data: user_state_data
        },
        socket
      ) do
    user_state_key = UserState.key(user, %{crew: crew.id}, "selected-task")

    {
      :ok,
      socket
      |> assign(
        work_items: work_items,
        crew: crew,
        user: user,
        timezone: timezone,
        panel_info: panel_info,
        user_state_key: user_state_key,
        user_state_data: user_state_data
      )
      |> update_title()
      |> update_participant()
      |> update_selected_item_id()
      |> update_selected_item()
      |> update_user_state_value()
      |> update_launcher()
      |> compose_child(:work_list_view)
      |> compose_child(@tool_ref_view_name)
      |> show_modal_tool_ref_view_if_needed()
    }
  end

  defp update_title(socket) do
    title = dgettext("eyra-assignment", "work.list.title")
    socket |> assign(title: title)
  end

  defp update_selected_item_id(%{assigns: %{selected_item_id: selected_item_id}} = socket)
       when not is_nil(selected_item_id) do
    socket
  end

  defp update_selected_item_id(
         %{assigns: %{user_state_data: user_state_data, user_state_key: user_state_key}} = socket
       ) do
    selected_item_id = UserState.integer_value(user_state_data, user_state_key)
    socket |> assign(selected_item_id: selected_item_id)
  end

  defp update_user_state_value(%{assigns: %{selected_item_id: selected_item_id}} = socket) do
    socket |> assign(user_state_value: selected_item_id)
  end

  defp update_user_state_value(socket) do
    socket |> assign(user_state_value: nil)
  end

  defp update_selected_item(%{assigns: %{selected_item_id: selected_item_id}} = socket)
       when not is_nil(selected_item_id) do
    selected_item =
      Enum.find(socket.assigns.work_items, fn {%{id: id}, _} -> id == selected_item_id end)

    socket |> assign(selected_item: selected_item)
  end

  defp update_selected_item(socket) do
    socket |> assign(selected_item: nil)
  end

  defp update_launcher(%{assigns: %{selected_item: selected_item}} = socket)
       when not is_nil(selected_item) do
    launcher = launcher(selected_item)
    socket |> assign(launcher: launcher)
  end

  defp update_launcher(socket) do
    socket |> assign(launcher: nil)
  end

  # Behaviours

  @impl true
  def handle_tool_exited(socket) do
    socket
    |> handle_task_completed()
    |> hide_modal_tool_ref_view()
  end

  @impl true
  def handle_tool_initialized(socket) do
    socket |> send_event(@tool_ref_view_name, "tool_initialized")
  end

  # Compose

  @impl true
  def compose(:work_list_view, %{work_items: work_items}) do
    work_list = %{
      items: Enum.map(work_items, &map_item/1),
      selected_item_id: nil
    }

    %{module: Workflow.WorkListView, params: %{work_list: work_list}}
  end

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
        user_state_data: user_state_data,
        participant: participant,
        timezone: timezone
      }
    }
  end

  def compose(@tool_ref_view_name, _) do
    nil
  end

  @impl true
  def handle_modal_closed(socket, @tool_ref_view_name) do
    socket
    |> assign(user_state_value: nil)
    |> assign(selected_item_id: nil)
    |> update_selected_item()
    |> update_launcher()
  end

  # Events

  @impl true
  def handle_event(
        "work_item_selected",
        %{"item" => item_id},
        socket
      ) do
    item_id = String.to_integer(item_id)

    {
      :noreply,
      socket |> start_item(item_id)
    }
  end

  def handle_event("hide_modal", _payload, socket) do
    {:noreply, socket |> hide_modal_tool_ref_view()}
  end

  def handle_event("tool_initialized", payload, socket) do
    {:noreply, socket |> send_event(@tool_ref_view_name, "tool_initialized", payload)}
  end

  def handle_event("complete_task", _, socket) do
    {:noreply, socket |> handle_task_completed()}
  end

  # Private

  defp start_item(socket, item_id) do
    socket
    |> assign(selected_item_id: item_id)
    |> update_user_state_value()
    |> update_selected_item()
    |> update_launcher()
    |> compose_child(@tool_ref_view_name)
    |> show_modal_tool_ref_view_if_needed()
    |> start_task()
  end

  defp start_task(%{assigns: %{selected_item: {_, task}}} = socket) do
    Assignment.Public.start_task(task)
    socket
  end

  defp show_modal_tool_ref_view_if_needed(%{assigns: %{selected_item: selected_item}} = socket)
       when not is_nil(selected_item) do
    socket |> show_modal(@tool_ref_view_name, :full)
  end

  defp show_modal_tool_ref_view_if_needed(socket) do
    socket
  end

  defp hide_modal_tool_ref_view(%{assigns: %{work_items: [_]}} = socket) do
    socket |> hide_modal(@tool_ref_view_name)
  end

  defp hide_modal_tool_ref_view(socket) do
    socket
    |> hide_modal(@tool_ref_view_name)
    |> assign(selected_item_id: nil)
    |> update_user_state_value()
    |> update_selected_item()
    |> update_launcher()
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div id="crew_task_list_view" class="w-full h-full" phx-hook="UserState" data-key={@user_state_key} data-value={@user_state_value} >
        <.task_list title={@title}>
          <.child name={:work_list_view} fabric={@fabric} />
        </.task_list>
      </div>
    """
  end
end
