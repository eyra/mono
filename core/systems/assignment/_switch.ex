defmodule Systems.Assignment.Switch do
  use Frameworks.Signal.Handler
  require Logger

  alias Core.Authorization

  alias Frameworks.{
    Signal
  }

  alias Systems.{
    Assignment,
    Workflow,
    NextAction
  }

  @impl true
  def intercept({:workflow, _} = signal, %{workflow: %Workflow.Model{} = workflow} = message) do
    if assignment =
         Assignment.Public.get_by_workflow(workflow, Assignment.Model.preload_graph(:down)) do
      dispatch!(
        {:assignment, signal},
        Map.merge(message, %{assignment: assignment})
      )
    end
  end

  @impl true
  def intercept({:assignment_info, _} = signal, %{info: %Assignment.InfoModel{} = info}) do
    handle(
      {:assignment, signal},
      Assignment.Public.get_by_info!(info, Assignment.Model.preload_graph(:down))
    )
  end

  @impl true
  def intercept({:assignment, _} = signal, %{assignment: %Assignment.Model{} = assignment}) do
    handle(signal, assignment)
  end

  def intercept(
        {:crew_task, :updated},
        %{
          data: %{status: old_status, crew_id: crew_id, auth_node_id: auth_node_id},
          changes: %{status: new_status}
        }
      ) do
    # crew does not have a director, so check if assignment is available to handle signal
    with [%{director: director} = assignment | _] <-
           Assignment.Public.list_by_crew(crew_id, budget: [:fund, :reserve, :currency]) do
      users = Authorization.users_with_role(auth_node_id, :owner)
      handle_next_action_check_rejection(old_status, new_status, assignment, users)

      case new_status do
        :accepted ->
          dispatch!({:assignment, :accepted}, %{
            director: director,
            assignment: assignment,
            users: users
          })

        :rejected ->
          dispatch!({:assignment, :rejected}, %{
            director: director,
            assignment: assignment,
            users: users
          })

        :pending ->
          nil

        :completed ->
          dispatch!({:assignment, :completed}, %{
            director: director,
            assignment: assignment,
            users: users
          })

        _ ->
          Logger.warning("Unknown crew task status: #{new_status}")
      end
    end
  end

  def intercept({:crew_task, _}, _task_changeset), do: :noop

  def intercept({:lab_tool, :reservations_cancelled}, %{tool: tool, user: user}) do
    # reset the membership (with new expiration time), so user has time to reserve a spot on a different time slot
    if assignment = Assignment.Public.get_by_tool(tool, [:crew]) do
      Assignment.Public.reset_member(assignment, user)
    end
  end

  def intercept({:lab_tool, :reservation_created}, %{tool: tool, user: user}) do
    if Assignment.Public.get_by_tool(tool) do
      Assignment.Public.lock_task(tool, user)
    end
  end

  def intercept(signal, %{director: :assignment} = object) do
    handle(signal, object)
  end

  defp handle(:workflow, workflow_id) do
    assignments = Assignment.Public.list_by_workflow(workflow_id)
    Enum.each(assignments, &Signal.Public.dispatch!({:assignment, :updated}, %{assignment: &1}))
  end

  defp handle({:assignment, _}, nil), do: nil

  defp handle({:assignment, _}, %Assignment.Model{} = assignment) do
    update_pages(assignment)
  end

  defp update_pages(%Assignment.Model{} = assignment) do
    [Assignment.ContentPage]
    |> Enum.each(&update_page(&1, assignment))
  end

  defp update_page(page, model) do
    dispatch!({:page, page}, %{id: model.id, model: model})
  end

  defp handle_next_action_check_rejection(
         old_status,
         new_status,
         %{id: assignment_id} = _assignment,
         users
       ) do
    opts = [key: "#{assignment_id}", params: %{id: assignment_id}]

    case {old_status, new_status} do
      {_, :rejected} ->
        NextAction.Public.create_next_action(users, Assignment.CheckRejection, opts)

      {:rejected, _} ->
        NextAction.Public.clear_next_action(users, Assignment.CheckRejection, opts)

      _ ->
        nil
    end
  end
end
