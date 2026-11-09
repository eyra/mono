defmodule Systems.Assignment.CrewTaskHorizontalListView do
  @moduledoc """
  The horizontal task list. Shows the participant's position in the tasks and
  the current task's start view below it. Tasks are done in order, without a done
  button: participation finishes when the last task is done.
  """
  use MicaWeb, :embedded_live_view
  use Systems.Assignment.CrewTaskHelpers

  import MicaWeb.UI.StepProgress

  alias Systems.Assignment
  alias Systems.Crew

  def dependencies(), do: [:assignment_id, :current_user, :panel_info]

  def get_model(:not_mounted_at_router, _session, %{assigns: %{assignment_id: assignment_id}}) do
    Assignment.Public.get!(assignment_id, [
      :crew,
      workflow: [items: [tool_ref: Systems.Workflow.ToolRefModel.preload_graph(:tool)]]
    ])
  end

  @impl true
  def mount(:not_mounted_at_router, _session, socket) do
    {:ok, socket |> assign(work_done?: false) |> handle_view_model_updated()}
  end

  # Tasks also complete outside this view (a questionnaire's callback, another device), so
  # the list follows the view model: on to the next unfinished task, or finish after the last
  @impl true
  def handle_view_model_updated(%{assigns: %{vm: %{work_item: work_item}}} = socket) do
    socket
    |> assign(work_item: work_item)
    |> maybe_start_task()
    |> maybe_finish()
  end

  # Behaviours

  @impl true
  def handle_tool_completed(%{assigns: %{work_item: {_, task}}} = socket) do
    {:ok, _} = Crew.Public.complete_task(task)

    socket
    |> update_view_model()
    |> handle_view_model_updated()
  end

  # The task left the participant's task list while the tool was open
  def handle_tool_completed(socket), do: socket

  @impl true
  def handle_tool_initialized(socket), do: socket

  # Private

  defp maybe_start_task(%{assigns: %{work_item: {_, %{started_at: nil} = task}}} = socket) do
    Assignment.Public.start_task(task)
    socket
  end

  defp maybe_start_task(socket), do: socket

  # The last task is done: participation finishes, once
  defp maybe_finish(%{assigns: %{vm: %{finished?: true}, work_done?: false}} = socket) do
    socket
    |> assign(work_done?: true)
    |> publish_event(:work_done)
  end

  defp maybe_finish(socket), do: socket

  @impl true
  def render(assigns) do
    ~H"""
      <div data-testid="crew-task-horizontal-list-view" class="w-full h-full flex flex-col">
        <div class="flex-shrink-0 px-6 py-6 sm:px-12">
          <.step_progress steps={@vm.steps} />
        </div>
        <.line />
        <div class="flex-1 min-h-0">
          <%= if @vm.tool_view do %>
            <.element {Map.from_struct(@vm.tool_view)} socket={@socket} />
          <% end %>
        </div>
      </div>
    """
  end
end
