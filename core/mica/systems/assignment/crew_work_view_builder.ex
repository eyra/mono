defmodule Systems.Assignment.CrewWorkViewBuilder do
  use Gettext, backend: MicaWeb.Gettext

  alias Systems.Assignment
  alias Systems.Consent

  def view_model(
        %{
          id: assignment_id,
          privacy_doc: privacy_doc,
          consent_agreement: consent_agreement,
          page_refs: page_refs
        } = assignment,
        %{current_user: user, user_state: user_state, live_context: context} = _assigns
      ) do
    task_view = Assignment.Private.task_view(assignment)
    context_menu_items = build_context_menu_items(assignment, user)

    intro_page_ref = Enum.find(page_refs, &(&1.key == :assignment_information))
    support_page_ref = Enum.find(page_refs, &(&1.key == :assignment_helpdesk))

    %{
      privacy_doc: privacy_doc,
      consent_agreement: consent_agreement,
      context_menu_items: context_menu_items,
      intro_page_ref: intro_page_ref,
      support_page_ref: support_page_ref,
      user: user,
      task_view: task_view(task_view, assignment_id, user_state, context),
      empty_message: empty_message(task_view)
    }
  end

  defp empty_message(:none), do: dgettext("eyra-assignment", "work.empty.message")
  defp empty_message(_task_view), do: nil

  defp build_context_menu_items(assignment, user) do
    [:assignment_information, :privacy, :consent, :assignment_helpdesk]
    |> Enum.map(&context_menu_item(&1, assignment, user))
    |> Enum.filter(&(not is_nil(&1)))
  end

  defp context_menu_item(:privacy = key, %{privacy_doc: privacy_doc}, _user) do
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

  # Shows the text the participant signed; participants who were never asked have none.
  defp context_menu_item(:consent = key, %{consent_agreement: consent_agreement}, user) do
    if consent_agreement && Consent.Public.has_signature(consent_agreement, user) do
      %{id: key, label: dgettext("eyra-assignment", "context.menu.consent.title")}
    else
      nil
    end
  end

  defp context_menu_item(:assignment_information = key, %{page_refs: page_refs}, _user) do
    if Enum.find(page_refs, &(&1.key == :assignment_information)) != nil do
      %{id: key, label: dgettext("eyra-assignment", "context.menu.information.title")}
    else
      nil
    end
  end

  defp context_menu_item(:assignment_helpdesk = key, %{page_refs: page_refs}, _user) do
    if Enum.find(page_refs, &(&1.key == key)) != nil do
      %{id: key, label: dgettext("eyra-assignment", "context.menu.support.title")}
    else
      nil
    end
  end

  # No items - no task view
  defp task_view(:none, _assignment_id, _user_state, _context), do: nil

  # Waiting for user_state
  defp task_view(_task_view, _assignment_id, nil, _context), do: nil

  # Single item - show single view
  defp task_view(:single, assignment_id, _user_state, context) do
    MicaWeb.Live.Element.prepare_live_view(
      "crew_task_single_view_#{assignment_id}",
      Assignment.CrewTaskSingleView,
      live_context: context
    )
  end

  # Multiple items - show list view
  defp task_view(:list, assignment_id, _user_state, context) do
    MicaWeb.Live.Element.prepare_live_view(
      "crew_task_list_view_#{assignment_id}",
      Assignment.CrewTaskListView,
      live_context: context
    )
  end
end
