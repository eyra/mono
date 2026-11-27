defmodule Systems.Assignment.CrewTaskSingleViewBuilder do
  import Systems.Assignment.CrewTaskHelpers,
    only: [build_work_items: 2, get_participant: 3, participant_task: 1, recovery_context: 3]

  alias Frameworks.Concept.LiveContext
  alias Systems.Assignment

  def view_model(
        %{crew: crew} = assignment,
        %{current_user: user, live_context: context} = assigns
      ) do
    work_items = build_work_items(assignment, user)
    # Single view: get the first (and only) work item
    work_item = List.first(work_items)

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
      work_item: work_item,
      tool_view: build_tool_view(work_item, context)
    }
  end

  defp build_tool_view({workflow_item, task}, context) do
    %{tool_ref: tool_ref, id: workflow_item_id, title: title, group: icon} = workflow_item

    context =
      LiveContext.extend(context, %{
        workflow_item_id: workflow_item_id,
        participant_task: participant_task(task),
        title: title,
        icon: icon,
        tool_ref_id: tool_ref.id,
        presentation: :embedded
      })

    Assignment.ToolViewFactory.prepare(tool_ref, context)
  end

  defp build_tool_view(nil, _context), do: nil
end
