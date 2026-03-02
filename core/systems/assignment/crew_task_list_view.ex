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
    {:ok, socket |> handle_view_model_updated()}
  end

  @impl true
  def handle_view_model_updated(
        %{assigns: %{vm: %{tool_modal: %{id: id}}, tool_modal: %{id: current_id}}} = socket
      )
      when id == current_id do
    # Same modal already presented, do nothing
    socket
  end

  def handle_view_model_updated(%{assigns: %{vm: %{tool_modal: tool_modal}}} = socket)
      when not is_nil(tool_modal) do
    socket
    |> assign(tool_modal: tool_modal)
    |> present_modal(tool_modal)
  end

  def handle_view_model_updated(socket), do: assign(socket, tool_modal: nil)

  # Behaviours

  @impl true
  def handle_tool_completed(
        %{assigns: %{tool_modal: tool_modal, vm: %{work_item: {_, task}}}} = socket
      )
      when not is_nil(tool_modal) do
    # First hide the modal, then complete task (which triggers signals that may kill this process)
    socket
    |> hide_modal(tool_modal)
    |> assign(tool_modal: nil)
    |> clear_task()
    |> complete_task(task)
  end

  def handle_tool_completed(%{assigns: %{vm: %{work_item: {_, task}}}} = socket) do
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
    {:stop, socket |> clear_task()}
  end

  # Private

  defp start_item(%{assigns: %{user_state: user_state}} = socket, item_id) do
    socket
    |> assign(user_state: Map.put(user_state, :task, item_id))
    |> update_view_model()
    |> handle_view_model_updated()
    |> start_task()
    |> publish_user_state_change(:task, item_id)
  end

  defp start_task(%{assigns: %{vm: %{work_item: {_, task}}}} = socket) do
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
    |> hide_modal(tool_modal)
    |> assign(tool_modal: nil)
    |> clear_task()
  end

  defp close_tool_modal(socket) do
    socket |> clear_task()
  end

  defp clear_task(%{assigns: %{user_state: user_state}} = socket) do
    socket
    |> assign(user_state: Map.put(user_state, :task, nil))
    |> update_view_model()
    |> handle_view_model_updated()
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
