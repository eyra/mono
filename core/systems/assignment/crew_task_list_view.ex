defmodule Systems.Assignment.CrewTaskListView do
  use CoreWeb, :embedded_live_view
  use Systems.Assignment.CrewTaskHelpers

  import Systems.Assignment.Html, only: [task_list: 1]

  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Workflow

  def dependencies(), do: [:assignment_id, :current_user, {:user_state, :task}, :panel_info]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{assignment_id: assignment_id}}) do
    Assignment.Public.get!(assignment_id, [
      :crew,
      workflow: [items: [tool_ref: Systems.Workflow.ToolRefModel.preload_graph(:down)]]
    ])
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket |> update_participant() |> init_work_item() |> maybe_present_tool_modal()}
  end

  # Initialize work_item from vm when restoring from user_state
  defp init_work_item(%{assigns: %{vm: %{work_item_id: work_item_id}}} = socket)
       when not is_nil(work_item_id) do
    socket
    |> assign(work_item_id: work_item_id)
    |> update_work_item()
  end

  defp init_work_item(socket), do: socket

  defp maybe_present_tool_modal(%{assigns: %{vm: %{tool_modal: tool_modal}}} = socket)
       when not is_nil(tool_modal) do
    socket
    |> assign(tool_modal: tool_modal)
    |> present_modal(tool_modal)
  end

  defp maybe_present_tool_modal(socket), do: assign(socket, tool_modal: nil)

  defp update_work_item(
         %{assigns: %{work_item_id: work_item_id, vm: %{work_items: work_items}}} = socket
       )
       when not is_nil(work_item_id) do
    work_item =
      Enum.find(work_items, fn {%{id: id}, _} -> id == work_item_id end)

    socket |> assign(work_item: work_item)
  end

  defp update_work_item(socket) do
    socket |> assign(work_item: nil)
  end

  defp maybe_show_tool_modal(
         %{
           assigns: %{
             work_item: {workflow_item, _task},
             live_context: context,
             participant: participant
           }
         } = socket
       ) do
    %{tool_ref: tool_ref, id: workflow_item_id, title: title, group: icon} = workflow_item

    task_context =
      Frameworks.Concept.LiveContext.extend(context, %{
        workflow_item_id: workflow_item_id,
        participant: participant,
        title: title,
        icon: icon,
        tool_ref: tool_ref
      })

    modal = Assignment.ToolViewFactory.prepare_modal(tool_ref, task_context, "tool_modal")

    socket
    |> assign(tool_modal: modal)
    |> present_modal(modal)
  end

  defp maybe_show_tool_modal(socket), do: socket

  # Behaviours

  @impl true
  def handle_tool_completed(%{assigns: %{tool_modal: tool_modal, work_item: {_, task}}} = socket)
      when not is_nil(tool_modal) do
    # First hide the modal, then complete task (which triggers signals that may kill this process)
    socket
    |> assign(work_item_id: nil, tool_modal: nil)
    |> update_work_item()
    |> hide_modal(tool_modal)
    |> clear_task()
    |> complete_task(task)
  end

  def handle_tool_completed(%{assigns: %{work_item: {_, task}}} = socket) do
    socket
    |> close_tool_modal()
    |> complete_task(task)
  end

  @impl true
  def handle_tool_initialized(socket) do
    # Tool initialized - no specific action needed for list view
    socket
  end

  # Events

  @impl true
  def consume_event(
        %{name: :work_item_selected, payload: %{"item" => item_id}},
        socket
      ) do
    item_id = String.to_integer(item_id)
    {:stop, socket |> start_item(item_id)}
  end

  # Called by LiveNest Modal Presenter when modal is closed
  def consume_event(%{name: :modal_closed, payload: %{modal_id: _modal_id}}, socket) do
    {:stop,
     socket
     |> assign(work_item_id: nil)
     |> update_work_item()
     |> clear_task()}
  end

  # Private

  defp start_item(socket, item_id) do
    socket
    |> assign(work_item_id: item_id)
    |> update_work_item()
    |> maybe_show_tool_modal()
    |> start_task()
    |> publish_user_state_change(:task, item_id)
  end

  defp start_task(%{assigns: %{work_item: {_, task}}} = socket) do
    Assignment.Public.start_task(task)
    socket
  end

  defp complete_task(socket, task) do
    {:ok, _} = Crew.Public.complete_task(task)

    socket
    |> publish_event(:task_completed)
  end

  defp close_tool_modal(%{assigns: %{tool_modal: tool_modal}} = socket)
       when not is_nil(tool_modal) do
    socket
    |> assign(work_item_id: nil, tool_modal: nil)
    |> update_work_item()
    |> hide_modal(tool_modal)
    |> clear_task()
  end

  defp close_tool_modal(socket) do
    socket
    |> assign(work_item_id: nil)
    |> update_work_item()
    |> clear_task()
  end

  defp clear_task(%{assigns: %{user_state: user_state}} = socket) do
    socket
    |> assign(user_state: Map.put(user_state, :task, nil))
    |> publish_user_state_change(:task, nil)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div data-testid="crew-task-list-view" class="w-full h-full overflow-y-auto">
        <.task_list>
          <.live_component module={Workflow.WorkListView} id="work_list" work_list={@vm.work_list} />
        </.task_list>
      </div>
    """
  end
end
