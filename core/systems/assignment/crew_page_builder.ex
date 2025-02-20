defmodule Systems.Assignment.CrewPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.{
    Assignment,
    Crew,
    Workflow,
    Consent,
    Account
  }

  def view_model(%{crew: crew} = assignment, %{current_user: user} = assigns) do
    %{
      flow: flow(assignment, assigns),
      info: assignment.info,
      crew: crew,
      crew_member: Crew.Public.get_member_unsafe(crew, user)
    }
  end

  defp flow(%{status: status} = assignment, %{current_user: user} = assigns) do
    tester? = Assignment.Public.tester?(assignment, user)

    if tester? or status == :online do
      flow(assignment, assigns, current_flow(assigns), tester?)
    else
      []
    end
  end

  defp flow(assignment, assigns, nil, tester?), do: full_flow(assignment, assigns, tester?)

  defp flow(assignment, assigns, current_flow, tester?) do
    full_flow(assignment, assigns, tester?)
    |> Enum.filter(fn %{ref: %{id: id}} ->
      Enum.find(current_flow, &(&1.ref.id == id)) != nil
    end)
  end

  defp full_flow(assignment, assigns, tester?) do
    [
      intro_view(assignment, assigns),
      consent_view(assignment, assigns, tester?),
      work_view(assignment, assigns, tester?)
    ]
    |> Enum.filter(&(not is_nil(&1)))
  end

  defp current_flow(%{fabric: %{children: children}}), do: children

  defp intro_view(
         %{id: assignment_id, page_refs: page_refs},
         %{current_user: user, fabric: fabric}
       ) do
    visited? = Account.Public.visited?(user, {:assignment_information, assignment_id})
    intro_page_ref = Enum.find(page_refs, &(&1.key == :assignment_information))

    if is_nil(intro_page_ref) or visited? do
      nil
    else
      Fabric.prepare_child(fabric, :onboarding_view_intro, Assignment.OnboardingView, %{
        page_ref: intro_page_ref,
        title: dgettext("eyra-assignment", "onboarding.intro.title"),
        user: user
      })
    end
  end

  defp consent_view(%{consent_agreement: nil}, _, _), do: nil

  defp consent_view(
         %{consent_agreement: consent_agreement},
         %{current_user: user, fabric: fabric},
         tester?
       ) do
    revision = Consent.Public.latest_revision(consent_agreement, [:signatures])
    signature = Consent.Public.get_signature(consent_agreement, user)

    case {revision, signature, tester?} do
      {_, signature, false} when not is_nil(signature) ->
        # normal flow: no consent view with signature
        nil

      {%{id: id}, %{revision_id: revision_id}, true} when id == revision_id ->
        # preview flow: no consent view with signature on the latest version
        nil

      _ ->
        Fabric.prepare_child(
          fabric,
          :onboarding_view_consent,
          Assignment.OnboardingConsentView,
          %{
            revision: revision,
            user: user
          }
        )
    end
  end

  defp work_view(
         %{
           privacy_doc: privacy_doc,
           consent_agreement: consent_agreement,
           page_refs: page_refs,
           crew: crew
         } = assignment,
         %{
           fabric: fabric,
           current_user: user,
           timezone: timezone,
           session: session
         } = assigns,
         tester?
       ) do
    panel_info = Map.get(session, "panel_info")
    work_items = work_items(assignment, assigns)
    context_menu_items = context_menu_items(assignment, assigns)

    intro_page_ref = Enum.find(page_refs, &(&1.key == :assignment_information))
    support_page_ref = Enum.find(page_refs, &(&1.key == :assignment_helpdesk))

    Fabric.prepare_child(fabric, :work_view, Assignment.CrewWorkView, %{
      work_items: work_items,
      privacy_doc: privacy_doc,
      consent_agreement: consent_agreement,
      context_menu_items: context_menu_items,
      intro_page_ref: intro_page_ref,
      support_page_ref: support_page_ref,
      crew: crew,
      user: user,
      timezone: timezone,
      panel_info: panel_info,
      tester?: tester?
    })
  end

  defp context_menu_items(assignment, _assigns) do
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

  defp work_items(%{status: status, crew: crew} = assignment, %{current_user: user}) do
    if Assignment.Public.tester?(assignment, user) or status == :online do
      member = Crew.Public.get_member(crew, user)
      work_items(assignment, member, user)
    else
      []
    end
  end

  defp work_items(%{workflow: workflow} = assignment, %{} = member, %{} = user) do
    ordered_items = Workflow.Model.ordered_items(workflow)
    Enum.map(ordered_items, &{&1, get_or_create_task(&1, assignment, member, user)})
  end

  defp work_items(_assignment, nil, _), do: []

  defp get_or_create_task(item, %{crew: crew} = assignment, member, user) do
    identifier = Assignment.Private.task_identifier(assignment, item, member)

    if task = Crew.Public.get_task(crew, identifier) do
      task
    else
      Crew.Public.create_task!(crew, [user], identifier)
    end
  end
end
