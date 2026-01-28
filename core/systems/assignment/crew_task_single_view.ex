defmodule Systems.Assignment.CrewTaskSingleView do
  use CoreWeb, :embedded_live_view
  use Systems.Assignment.CrewTaskHelpers

  alias Systems.Assignment
  alias Systems.Crew

  def dependencies(), do: [:assignment_id, :current_user, :panel_info]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{assignment_id: assignment_id}}) do
    Assignment.Public.get!(assignment_id, [
      :crew,
      workflow: [items: [tool_ref: Systems.Workflow.ToolRefModel.preload_graph(:down)]]
    ])
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket |> maybe_start_task()}
  end

  defp maybe_start_task(%{assigns: %{vm: %{work_item: {_, task} = work_item}}} = socket) do
    if is_nil(task.started_at) do
      Assignment.Public.start_task(task)
    end

    socket |> assign(work_item: work_item)
  end

  defp maybe_start_task(socket), do: socket

  @impl true
  def handle_view_model_updated(socket) do
    socket
  end

  # Behaviours

  @impl true
  def handle_tool_completed(socket) do
    socket |> complete_task()
  end

  @impl true
  def handle_tool_initialized(socket) do
    # Tool initialized - no action needed
    socket
  end

  # Events

  @impl true
  def handle_event("complete_task", _, socket) do
    {:noreply, socket |> complete_task()}
  end

  @impl true
  def handle_info({:signal_test, _}, socket) do
    {:noreply, socket}
  end

  # Private

  defp complete_task(%{assigns: %{work_item: {_workflow_item, task}}} = socket)
       when not is_nil(task) do
    {:ok, _} = Crew.Public.complete_task(task)

    socket
    |> publish_event(:work_done)
  end

  defp complete_task(socket), do: socket

  @impl true
  def render(assigns) do
    ~H"""
      <div data-testid="crew-task-single-view" class="w-full h-full flex flex-col px-4 pt-4 sm:px-8 sm:pt-8">
        <%= if @vm.tool_view do %>
          <.element {Map.from_struct(@vm.tool_view)} socket={@socket} />
        <% end %>
      </div>
    """
  end
end
