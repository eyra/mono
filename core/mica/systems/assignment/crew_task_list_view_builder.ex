defmodule Systems.Assignment.CrewTaskListViewBuilder do
  use Gettext, backend: MicaWeb.Gettext

  import Systems.Assignment.CrewTaskHelpers,
    only: [map_item: 1, build_work_items: 2, get_participant: 3, recovery_context: 3]

  alias Frameworks.Concept.LiveContext
  alias Systems.Assignment

  def view_model(
        %{crew: crew} = assignment,
        %{
          current_user: user,
          user_state: user_state,
          live_context: context
        } = assigns
      ) do
    work_items = build_work_items(assignment, user)
    work_item_id = user_state[:task]
    work_item = find_work_item(work_items, work_item_id)

    # Compute participant here to avoid timing issues (mount runs AFTER ViewBuilder)
    assignment_id = Map.get(assigns, :assignment_id)
    participant = get_participant(crew, user, assigns)

    context =
      LiveContext.extend(context, %{
        assignment_id: assignment_id,
        participant: participant,
        recovery: recovery_context(assignment, user, work_item)
      })

    tool_modal = build_tool_modal(work_item, context)

    %{
      work_list: %{
        items: Enum.map(work_items, &map_item/1),
        selected_item_id: nil,
        done_button?: done_button?(assignment, context)
      },
      work_items: work_items,
      work_item_id: work_item_id,
      work_item: work_item,
      tool_modal: tool_modal,
      task_context: context,
      participant: participant
    }
  end

  defp find_work_item(work_items, work_item_id) when not is_nil(work_item_id) do
    Enum.find(work_items, fn {%{id: id}, _} -> id == work_item_id end)
  end

  defp find_work_item(_, _), do: nil

  defp done_button?(assignment, %{data: data}) do
    case Assignment.Private.runtime_config(assignment) do
      %{done_button_requires_redirect?: true} -> redirect_url?(Map.get(data, :panel_info))
      _ -> true
    end
  end

  defp redirect_url?(%{redirect_url: url}) when is_binary(url) and url != "", do: true

  defp redirect_url?(_), do: false

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
