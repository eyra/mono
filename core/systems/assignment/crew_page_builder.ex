defmodule Systems.Assignment.CrewPageBuilder do
  alias Systems.{
    Assignment,
    Crew,
    Workflow,
    Consent
  }

  def view_model(assignment, assigns) do
    %{
      flow: flow(assignment, assigns)
    }
  end

  defp flow(%{status: status} = assignment, assigns) do
    if is_tester?(assignment, assigns) or status == :online do
      flow(assignment, assigns, current_flow(assigns))
    else
      []
    end
  end

  defp flow(assignment, assigns, nil), do: full_flow(assignment, assigns)

  defp flow(assignment, assigns, current_flow) do
    full_flow(assignment, assigns)
    |> Enum.filter(fn %{ref: %{id: id}} ->
      Enum.find(current_flow, &(&1.ref.id == id)) != nil
    end)
  end

  defp full_flow(assignment, assigns) do
    [
      consent_view(assignment, assigns),
      work_view(assignment, assigns)
    ]
    |> Enum.filter(&(&1 != nil))
  end

  defp current_flow(%{fabric: %{children: children}}), do: children

  defp consent_view(%{consent_agreement: nil}, _), do: nil

  defp consent_view(%{consent_agreement: consent_agreement}, %{current_user: user, fabric: fabric}) do
    revision = Consent.Public.latest_revision(consent_agreement)

    Fabric.prepare_child(fabric, :onboarding_view, Assignment.OnboardingConsentView, %{
      revision: revision,
      user: user
    })
  end

  defp work_view(assignment, %{fabric: fabric} = assigns) do
    work_items = work_items(assignment, assigns)

    Fabric.prepare_child(fabric, :work_view, Assignment.CrewWorkView, %{
      work_items: work_items
    })
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
      Crew.Public.create_task(crew, [member], identifier)
    end
  end
end
