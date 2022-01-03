defmodule Systems.Assignment.Switch do
  use Frameworks.Signal.Handler
  require Logger
  alias Core.Accounts

  alias Frameworks.{
    Signal
  }

  alias Systems.{
    Assignment,
    Crew,
    NextAction
  }

  def dispatch(:crew_task_updated, %{
        data: %{status: old_status, member_id: member_id, crew_id: crew_id},
        changes: %{status: new_status}
      }) do
    # crew does not have a director (yet), so check if assignment is available to handle signal
    with [%{id: assignment_id} | _] <- Assignment.Context.get_by_crew!(crew_id) do
      %{user_id: user_id} = Crew.Context.get_member!(member_id)
      user = Accounts.get_user!(user_id)

      opts = [key: "#{assignment_id}", params: %{id: assignment_id}]

      case {old_status, new_status} do
        {_, :rejected} ->
          NextAction.Context.create_next_action(user, Assignment.CheckRejection, opts)

        {:rejected, _} ->
          NextAction.Context.clear_next_action(user, Assignment.CheckRejection, opts)

        _ ->
          nil
      end
    end
  end

  def dispatch(:crew_task_updated, _task_changeset), do: :noop

  def dispatch(signal, %{director: :assignment} = object) do
    handle(signal, object)
  end

  def handle(:survey_tool_updated, tool), do: handle(:assignable_updated, tool)
  def handle(:lab_tool_updated, tool), do: handle(:assignable_updated, tool)
  def handle(:data_donation_tool_updated, tool), do: handle(:assignable_updated, tool)

  def handle(:assignable_updated, assignable) do
    assignment = Assignment.Context.get_by_assignable(assignable)
    Signal.Context.dispatch!(:assignment_updated, assignment)
  end
end
