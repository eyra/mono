defmodule Systems.Assignment.CrewWorkViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Assignment
  alias Systems.Workflow

  def view_model(
        %{
          id: assignment_id,
          privacy_doc: privacy_doc,
          consent_agreement: consent_agreement,
          page_refs: page_refs,
          workflow: workflow
        } = assignment,
        %{current_user: user, user_state: user_state, live_context: context} = _assigns
      ) do
    item_count = workflow |> Workflow.Model.ordered_items() |> length()
    context_menu_items = build_context_menu_items(assignment)

    intro_page_ref = Enum.find(page_refs, &(&1.key == :assignment_information))
    support_page_ref = Enum.find(page_refs, &(&1.key == :assignment_helpdesk))

    %{
      privacy_doc: privacy_doc,
      consent_agreement: consent_agreement,
      context_menu_items: context_menu_items,
      intro_page_ref: intro_page_ref,
      support_page_ref: support_page_ref,
      user: user,
      task_view: task_view(item_count, assignment_id, user_state, context)
    }
  end

  defp build_context_menu_items(assignment) do
    [:assignment_information, :privacy, :consent, :assignment_helpdesk]
    |> Enum.map(&context_menu_item(&1, assignment))
    |> Enum.filter(&(not is_nil(&1)))
  end

  defp context_menu_item(:privacy = key, %{privacy_doc: privacy_doc}) do
    if privacy_doc do
      %{
        id: key,
        label: dgettext("eyra-assignment", "context.menu.privacy.title"),
        url: privacy_doc.ref
      }
    else
      nil
    end
  end

  defp context_menu_item(:consent = key, %{consent_agreement: consent_agreement}) do
    if consent_agreement do
      %{id: key, label: dgettext("eyra-assignment", "context.menu.consent.title")}
    else
      nil
    end
  end

  defp context_menu_item(:assignment_information = key, %{page_refs: page_refs}) do
    if Enum.find(page_refs, &(&1.key == :assignment_information)) != nil do
      %{id: key, label: dgettext("eyra-assignment", "context.menu.information.title")}
    else
      nil
    end
  end

  defp context_menu_item(:assignment_helpdesk = key, %{page_refs: page_refs}) do
    if Enum.find(page_refs, &(&1.key == key)) != nil do
      %{id: key, label: dgettext("eyra-assignment", "context.menu.support.title")}
    else
      nil
    end
  end

  # No items - no task view
  defp task_view(0, _assignment_id, _user_state, _context), do: nil

  # Waiting for user_state
  defp task_view(_item_count, _assignment_id, nil, _context), do: nil

  # Single item - show single view
  defp task_view(1, assignment_id, _user_state, context) do
    LiveNest.Element.prepare_live_view(
      "crew_task_single_view_#{assignment_id}",
      Assignment.CrewTaskSingleView,
      live_context: context
    )
  end

  # Multiple items - show list view
  defp task_view(_item_count, assignment_id, _user_state, context) do
    LiveNest.Element.prepare_live_view(
      "crew_task_list_view_#{assignment_id}",
      Assignment.CrewTaskListView,
      live_context: context
    )
  end
end
