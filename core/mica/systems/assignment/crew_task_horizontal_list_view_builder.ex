defmodule Systems.Assignment.CrewTaskHorizontalListViewBuilder do
  @moduledoc """
  The horizontal task list: one step per task, done in order. The current task
  is the first one that isn't finished, so a participant who comes back lands on
  it. Its tool view loads below the steps.
  """
  use Gettext, backend: MicaWeb.Gettext

  import Systems.Assignment.CrewTaskHelpers,
    only: [build_work_items: 2, get_participant: 3, recovery_context: 3]

  alias Frameworks.Concept.LiveContext
  alias Systems.Assignment
  alias Systems.Crew

  def view_model(
        %{crew: crew} = assignment,
        %{current_user: user, live_context: context} = assigns
      ) do
    work_items = build_work_items(assignment, user)
    current_index = Enum.find_index(work_items, &(not finished?(&1)))
    work_item = current_index && Enum.at(work_items, current_index)

    # Compute participant here to avoid timing issues (mount runs AFTER ViewBuilder)
    assignment_id = Map.get(assigns, :assignment_id)
    participant = get_participant(crew, user, assigns)

    context =
      LiveContext.extend(context, %{
        assignment_id: assignment_id,
        participant: participant,
        recovery: recovery_context(assignment, user, work_item)
      })

    %{
      steps: build_steps(work_items, current_index),
      work_item: work_item,
      tool_view: build_tool_view(work_item, context)
    }
  end

  defp finished?({_workflow_item, %{status: status}}),
    do: status in Crew.TaskStatus.finished_states()

  defp build_steps(work_items, current_index) do
    count = length(work_items)

    work_items
    |> Enum.with_index()
    |> Enum.map(fn {{%{id: id}, _task}, index} ->
      %{
        id: id,
        label:
          dgettext("eyra-assignment", "task_steps.step.label", index: index + 1, count: count),
        status: step_status(index, current_index)
      }
    end)
  end

  defp step_status(_index, nil), do: :complete
  defp step_status(index, current_index) when index < current_index, do: :complete
  defp step_status(index, current_index) when index == current_index, do: :current
  defp step_status(_index, _current_index), do: :incomplete

  # The tool's start view loads on the page; the tool itself opens in a modal over it
  defp build_tool_view({workflow_item, _task}, context) do
    %{tool_ref: tool_ref, id: workflow_item_id, title: title, group: icon} = workflow_item

    context =
      LiveContext.extend(context, %{
        workflow_item_id: workflow_item_id,
        title: title,
        icon: icon,
        tool_ref: tool_ref,
        presentation: :start_on_page
      })

    Assignment.ToolViewFactory.prepare(tool_ref, context, "tool_view_#{workflow_item_id}")
  end

  defp build_tool_view(nil, _context), do: nil
end
