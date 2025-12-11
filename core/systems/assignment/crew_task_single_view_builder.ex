defmodule Systems.Assignment.CrewTaskSingleViewBuilder do
  import Systems.Assignment.CrewTaskHelpers, only: [build_work_items: 2]

  alias Frameworks.Concept.LiveContext
  alias Systems.Assignment

  def view_model(assignment, %{current_user: user, live_context: context}) do
    work_items = build_work_items(assignment, user)
    # Single view: get the first (and only) work item
    work_item = List.first(work_items)

    %{
      work_item: work_item,
      tool_view: build_tool_view(work_item, context)
    }
  end

  defp build_tool_view({workflow_item, _task}, context) do
    %{tool_ref: tool_ref, id: workflow_item_id, title: title, group: icon} = workflow_item

    context =
      LiveContext.extend(context, %{
        workflow_item_id: workflow_item_id,
        title: title,
        icon: icon,
        tool_ref: tool_ref,
        presentation: :embedded
      })

    Assignment.ToolViewFactory.prepare(tool_ref, context)
  end

  defp build_tool_view(nil, _context), do: nil
end
