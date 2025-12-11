defmodule Systems.Assignment.CrewTaskListViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  import Systems.Assignment.CrewTaskHelpers, only: [map_item: 1, build_work_items: 2]

  alias Frameworks.Concept.LiveContext
  alias Systems.Assignment

  def view_model(assignment, %{
        current_user: user,
        user_state: user_state,
        live_context: context
      }) do
    work_items = build_work_items(assignment, user)
    work_item_id = user_state[:task]
    work_item = find_work_item(work_items, work_item_id)
    tool_modal = build_tool_modal(work_item, context)

    %{
      title: dgettext("eyra-assignment", "work.list.title"),
      work_list: %{
        items: Enum.map(work_items, &map_item/1),
        selected_item_id: nil
      },
      work_items: work_items,
      work_item_id: work_item_id,
      tool_modal: tool_modal
    }
  end

  defp find_work_item(work_items, work_item_id) when not is_nil(work_item_id) do
    Enum.find(work_items, fn {%{id: id}, _} -> id == work_item_id end)
  end

  defp find_work_item(_, _), do: nil

  defp build_tool_modal({workflow_item, _task}, context) do
    %{tool_ref: tool_ref, id: workflow_item_id, title: title, group: icon} = workflow_item

    task_context =
      LiveContext.extend(context, %{
        workflow_item_id: workflow_item_id,
        title: title,
        icon: icon,
        tool_ref: tool_ref,
        presentation: :modal
      })

    Assignment.ToolViewFactory.prepare_modal(tool_ref, task_context, "tool_modal")
  end

  defp build_tool_modal(nil, _context), do: nil
end
