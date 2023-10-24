defmodule Systems.Assignment.CrewPageBuilder do
  alias Systems.{
    Assignment,
    Crew,
    Workflow,
    Consent
  }

  def view_model(assignment, assigns) do
    %{
      onboarding: onboarding(assignment, assigns),
      items: items(assignment, assigns)
    }
  end

  defp onboarding(%{status: status} = assignment, assigns) do
    if is_tester?(assignment, assigns) or status == :online do
      onboarding(assignment, assigns, current_onboarding(assigns))
    else
      []
    end
  end

  defp onboarding(assignment, assigns, nil), do: full_onboarding(assignment, assigns)

  defp onboarding(assignment, assigns, current_onboarding) do
    full_onboarding(assignment, assigns)
    |> Enum.filter(fn %{id: id} ->
        Enum.find(current_onboarding, & &1.id == id) != nil
      end)
  end

  defp full_onboarding(assignment, assigns) do
    [consent_view(assignment, assigns)]
  end

  defp current_onboarding(%{onboarding: onboarding}), do: onboarding
  defp current_onboarding(_), do: nil

  defp consent_view(%{consent_agreement: consent_agreement}, %{current_user: user}) do
    revision = Consent.Public.latest_revision(consent_agreement)

    %{
      id: :onboarding_consent_view,
      module: Assignment.OnboardingConsentView,
      revision: revision,
      user: user
    }
  end

  defp items(%{status: status, crew: crew} = assignment, %{current_user: user} = assigns) do
    if is_tester?(assignment, assigns) or status == :online do
      member = Crew.Public.get_member(crew, user)
      items(assignment, member)
    else
      []
    end
  end

  defp items(%{workflow: workflow} = assignment, %{} = member) do
    ordered_items = Workflow.Model.ordered_items(workflow)
    Enum.map(ordered_items, &{&1, get_or_create_task(&1, assignment, member)})
  end

  defp items(_assignment, nil), do: []

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
