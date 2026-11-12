defmodule Systems.Assignment.CrewTaskHorizontalListView do
  @moduledoc """
  The horizontal task list. Shows the participant's position in the tasks and
  the current task's intro below it. Its start button opens the tool in the same
  modal as the vertical task list. Tasks are done in order, without a done button:
  participation finishes when the last task is done.
  """
  use MicaWeb, :embedded_live_view
  use Systems.Assignment.CrewTaskHelpers

  import MicaWeb.UI.StepProgress

  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text
  alias Systems.Assignment
  alias Systems.Crew

  def dependencies(), do: [:assignment_id, :current_user, {:user_state, :task}, :panel_info]

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
    |> update_tool_modal()
    |> maybe_finish()
  end

  # Same modal already presented, do nothing
  defp update_tool_modal(
         %{
           assigns: %{
             vm: %{tool_modal: %{element: %{id: id}}},
             tool_modal: %{element: %{id: current_id}}
           }
         } = socket
       )
       when id == current_id,
       do: socket

  defp update_tool_modal(%{assigns: %{vm: %{tool_modal: tool_modal}}} = socket)
       when not is_nil(tool_modal) do
    socket
    |> assign(tool_modal: tool_modal)
    |> present_modal(tool_modal)
  end

  # The open task finished elsewhere or left the participant's task list: close its modal
  defp update_tool_modal(%{assigns: %{tool_modal: tool_modal}} = socket)
       when not is_nil(tool_modal) do
    socket
    |> hide_modal(tool_modal)
    |> assign(tool_modal: nil)
  end

  defp update_tool_modal(socket), do: assign(socket, tool_modal: nil)

  # Behaviours

  # Completes only the task whose tool is open: a second completion from the same tool
  # (a double click on Done) or one for a task already finished elsewhere must not
  # complete the task the list has moved on to
  @impl true
  def handle_tool_completed(
        %{assigns: %{work_item: {%{id: id}, task}, user_state: %{task: id}}} = socket
      ) do
    socket
    |> close_tool_modal()
    |> complete_task(task)
  end

  # The open task isn't the current one any more (finished, or it left the task list)
  def handle_tool_completed(socket), do: close_tool_modal(socket)

  @impl true
  def handle_tool_initialized(socket), do: socket

  # Events

  @impl true
  def handle_event("start_task", _, %{assigns: %{work_item: {%{id: item_id}, _}}} = socket) do
    {:noreply, socket |> start_item(item_id)}
  end

  def handle_event("start_task", _, socket), do: {:noreply, socket}

  # Called by LiveNest Modal Presenter when modal is closed: back to the task's intro
  @impl true
  def consume_event(%{name: :modal_closed, payload: %{modal_id: _modal_id}}, socket) do
    {:stop, socket |> assign(tool_modal: nil) |> clear_task()}
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

  defp start_task(%{assigns: %{work_item: {_, task}}} = socket) do
    Assignment.Public.start_task(task)
    socket
  end

  defp complete_task(socket, task) do
    {:ok, _} = Crew.Public.complete_task(task)

    socket
    |> update_view_model()
    |> handle_view_model_updated()
  end

  defp close_tool_modal(%{assigns: %{tool_modal: tool_modal}} = socket)
       when not is_nil(tool_modal) do
    socket
    |> hide_modal(tool_modal)
    |> assign(tool_modal: nil)
    |> clear_task()
  end

  defp close_tool_modal(socket), do: clear_task(socket)

  defp clear_task(%{assigns: %{user_state: user_state}} = socket) do
    socket
    |> assign(user_state: Map.put(user_state, :task, nil))
    |> update_view_model()
    |> handle_view_model_updated()
    |> publish_user_state_change(:task, nil)
  end

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
        <div class="flex-shrink-0 px-6 py-3 sm:px-12">
          <.step_progress steps={@vm.steps} />
        </div>
        <.line />
        <div :if={@vm.intro} class="flex flex-col gap-6 w-full max-w-[720px] p-6 sm:p-12" data-testid="task-intro">
          <div class="flex flex-row items-center gap-4">
            <.step_number number={@vm.intro.number} />
            <Text.title3 margin=""><%= @vm.intro.title %></Text.title3>
          </div>
          <div :if={@vm.intro.description} class="text-bodysmall sm:text-bodymedium font-body text-grey1">
            <%= @vm.intro.description %>
          </div>
          <div class="pt-2">
            <Button.dynamic {@vm.intro.button} />
          </div>
        </div>
      </div>
    """
  end
end
