defmodule Systems.Assignment.CrewPageBuilder do
  alias Systems.{
    Assignment,
    Crew,
    Workflow
  }

  def view_model(
        %{crew: crew, status: status} = assignment,
        %{current_user: user} = _assigns
      ) do
    member = Crew.Public.get_member(crew, user)

    items =
      if status == :online or Core.Authorization.user_has_role?(user, crew, :tester) do
        items(assignment, member)
      else
        # offline mode
        []
      end

    %{
      items: items
    }
  end

  defp items(%{workflow: workflow} = assignment, member) do
    ordered_items = Workflow.Model.ordered_items(workflow)
    Enum.map(ordered_items, &{&1, get_or_create_task(&1, assignment, member)})
  end

  defp items(_assignment, nil), do: []

  defp get_or_create_task(item, %{crew: crew} = assignment, member) do
    identifier = Assignment.Private.task_identifier(assignment, item, member)

    if task = Crew.Public.get_task(crew, identifier) do
      task
    else
      Crew.Public.create_task(crew, [member], identifier)
    end
  end
end
