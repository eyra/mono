defmodule Systems.Assignment.CrewPageBuilder do
  import CoreWeb.Gettext

  alias Systems.{
    Assignment,
    Crew,
    Workflow,
    Consent
  }

  def view_model(assignment, assigns) do
    %{
      flow: flow(assignment, assigns),
      info: assignment.info
    }
  end

  defp flow(%{status: status} = assignment, assigns) do
    is_tester? = is_tester?(assignment, assigns)

    if is_tester? or status == :online do
      flow(assignment, assigns, current_flow(assigns), is_tester?)
    else
      []
    end
  end

  defp flow(assignment, assigns, nil, is_tester?), do: full_flow(assignment, assigns, is_tester?)

  defp flow(assignment, assigns, current_flow, is_tester?) do
    full_flow(assignment, assigns, is_tester?)
    |> Enum.filter(fn %{ref: %{id: id}} ->
      Enum.find(current_flow, &(&1.ref.id == id)) != nil
    end)
  end

  defp full_flow(assignment, assigns, is_tester?) do
    [
      intro_view(assignment, assigns),
      consent_view(assignment, assigns, is_tester?),
      work_view(assignment, assigns, is_tester?)
    ]
    |> Enum.filter(&(not is_nil(&1)))
  end

  defp current_flow(%{fabric: %{children: children}}), do: children

  defp intro_view(
         %{page_refs: page_refs},
         %{fabric: fabric}
       ) do
    if intro_page_ref = Enum.find(page_refs, &(&1.key == :assignment_intro)) do
      Fabric.prepare_child(fabric, :onboarding_view_intro, Assignment.OnboardingView, %{
        page_ref: intro_page_ref,
        title: dgettext("eyra-assignment", "onboarding.intro.title")
      })
    else
      nil
    end
  end

  defp consent_view(%{consent_agreement: nil}, _, _), do: nil

  defp consent_view(
         %{consent_agreement: consent_agreement},
         %{current_user: user, fabric: fabric},
         is_tester?
       ) do
    if Consent.Public.has_signature(consent_agreement, user) and not is_tester? do
      nil
    else
      revision = Consent.Public.latest_revision(consent_agreement, [:signatures])

      Fabric.prepare_child(fabric, :onboarding_view_consent, Assignment.OnboardingConsentView, %{
        revision: revision,
        user: user
      })
    end
  end

  defp work_view(
         %{consent_agreement: consent_agreement, page_refs: page_refs} = assignment,
         %{fabric: fabric, current_user: user} = assigns,
         _
       ) do
    work_items = work_items(assignment, assigns)
    context_menu_items = context_menu_items(assignment, assigns)

    intro_page_ref = Enum.find(page_refs, &(&1.key == :assignment_intro))
    support_page_ref = Enum.find(page_refs, &(&1.key == :assignment_support))

    Fabric.prepare_child(fabric, :work_view, Assignment.CrewWorkView, %{
      work_items: work_items,
      consent_agreement: consent_agreement,
      context_menu_items: context_menu_items,
      intro_page_ref: intro_page_ref,
      support_page_ref: support_page_ref,
      user: user
    })
  end

  defp context_menu_items(assignment, _assigns) do
    [:consent, :assignment_intro, :assignment_support]
    |> Enum.map(&context_menu_item(&1, assignment))
    |> Enum.filter(&(not is_nil(&1)))
  end

  defp context_menu_item(:consent = key, %{consent_agreement: consent_agreement}) do
    if consent_agreement do
      %{id: key, label: "Consent"}
    else
      nil
    end
  end

  defp context_menu_item(:assignment_intro = key, %{page_refs: page_refs}) do
    if Enum.find(page_refs, &(&1.key == :assignment_intro)) != nil do
      %{id: key, label: dgettext("eyra-assignment", "onboarding.intro.title")}
    else
      nil
    end
  end

  defp context_menu_item(:assignment_support = key, %{page_refs: page_refs}) do
    if Enum.find(page_refs, &(&1.key == key)) != nil do
      %{id: key, label: dgettext("eyra-assignment", "support.page.title")}
    else
      nil
    end
  end

  defp work_items(%{status: status, crew: crew} = assignment, %{current_user: user} = assigns) do
    if is_tester?(assignment, assigns) or status == :online do
      member = Crew.Public.get_member(crew, user)
      work_items(assignment, member)
    else
      []
    end
  end

  defp work_items(%{workflow: workflow} = assignment, %{} = member) do
    ordered_items = Workflow.Model.ordered_items(workflow)
    Enum.map(ordered_items, &{&1, get_or_create_task(&1, assignment, member)})
  end

  defp work_items(_assignment, nil), do: []

  defp is_tester?(%{crew: crew}, %{current_user: user}) do
    Core.Authorization.user_has_role?(user, crew, :tester)
  end

  defp get_or_create_task(item, %{crew: crew} = assignment, member) do
    identifier = Assignment.Private.task_identifier(assignment, item, member)

    if task = Crew.Public.get_task(crew, identifier) do
      task
    else
      Crew.Public.create_task!(crew, [member], identifier)
    end
  end
end
