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

  def dispatch(
        :crew_task_updated,
        %{
          data: %{status: old_status, member_id: member_id, crew_id: crew_id},
          changes: %{status: new_status}
        }
      ) do
    # crew does not have a director (yet), so check if assignment is available to handle signal
    with [%{director: director} = assignment | _] <-
           Assignment.Public.get_by_crew!(crew_id, budget: [:fund, :reserve, :currency]) do
      %{user_id: user_id} = Crew.Public.get_member!(member_id)
      user = Accounts.get_user!(user_id)

      handle_next_action_check_rejection(old_status, new_status, assignment, user)

      case new_status do
        :accepted ->
          Signal.Public.dispatch!(:assignment_accepted, %{
            director: director,
            assignment: assignment,
            user: user
          })

        :rejected ->
          Signal.Public.dispatch!(:assignment_rejected, %{
            director: director,
            assignment: assignment,
            user: user
          })

        :pending ->
          nil

        :completed ->
          Signal.Public.dispatch!(:assignment_completed, %{
            director: director,
            assignment: assignment,
            user: user
          })

        _ ->
          Logger.warning("Unknown crew task status: #{new_status}")
      end
    end
  end

  def dispatch(:crew_task_updated, _task_changeset), do: :noop

  def dispatch(:lab_reservations_cancelled, %{tool: tool, user: user}) do
    # reset the membership (with new expiration time), so user has time to reserve a spot on a different time slot
    if experiment = Assignment.Public.get_experiment_by_tool(tool) do
      experiment
      |> Assignment.Public.get_by_assignable([:crew])
      |> Assignment.Public.reset_member(user)

      handle(:lab_tool_updated, tool)
    end
  end

  def dispatch(:lab_reservation_created, %{tool: tool, user: user}) do
    if experiment = Assignment.Public.get_experiment_by_tool(tool) do
      experiment
      |> Assignment.Public.get_by_assignable([:crew])
      |> Assignment.Public.lock_task(user)

      handle(:lab_tool_updated, tool)
    end
  end

  def dispatch(signal, %{director: :assignment} = object) do
    handle(signal, object)
  end

  def handle(:questionnaire_tool_updated, tool), do: handle(:tool_updated, tool)
  def handle(:lab_tool_updated, tool), do: handle(:tool_updated, tool)
  def handle(:data_donation_tool_updated, tool), do: handle(:tool_updated, tool)

  def handle(:tool_updated, tool) do
    experiment = Assignment.Public.get_experiment_by_tool(tool)
    handle(:experiment_updated, experiment)
  end

  def handle(:experiment_updated, experiment), do: handle(:assignable_updated, experiment)

  def handle(:assignable_updated, assignable) do
    assignment = Assignment.Public.get_by_assignable(assignable)
    Signal.Public.dispatch!(:assignment_updated, assignment)
  end

  defp handle_next_action_check_rejection(
         old_status,
         new_status,
         %{id: assignment_id} = _assignment,
         user
       ) do
    opts = [key: "#{assignment_id}", params: %{id: assignment_id}]

    case {old_status, new_status} do
      {_, :rejected} ->
        NextAction.Public.create_next_action(user, Assignment.CheckRejection, opts)

      {:rejected, _} ->
        NextAction.Public.clear_next_action(user, Assignment.CheckRejection, opts)

      _ ->
        nil
    end
  end
end
