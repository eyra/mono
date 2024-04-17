defmodule Systems.Assignment.Switch do
  use Frameworks.Signal.Handler
  require Logger

  alias Core.Authorization

  alias Frameworks.Signal

  alias Systems.Assignment
  alias Systems.Workflow
  alias Systems.Crew
  alias Systems.NextAction

  @impl true
  def intercept({:workflow, _} = signal, %{workflow: workflow} = message) do
    if assignment = Assignment.Public.get_by(workflow, Assignment.Model.preload_graph(:down)) do
      dispatch!(
        {:assignment, signal},
        Map.merge(message, %{assignment: assignment})
      )
    end

    :ok
  end

  @impl true
  def intercept({:crew, _} = signal, %{crew: crew} = message) do
    if assignment = Assignment.Public.get_by(crew, Assignment.Model.preload_graph(:down)) do
      dispatch!(
        {:assignment, signal},
        Map.merge(message, %{assignment: assignment})
      )
    end

    :ok
  end

  @impl true
  def intercept({:assignment_info, _} = signal, %{assignment_info: info} = message) do
    if assignment = Assignment.Public.get_by(info, Assignment.Model.preload_graph(:down)) do
      dispatch!(
        {:assignment, signal},
        Map.merge(message, %{assignment: assignment})
      )
    end

    :ok
  end

  @impl true
  def intercept({:storage_endpoint, _} = signal, %{storage_endpoint: storage_endpoint} = message) do
    if assignment =
         Assignment.Public.get_by(storage_endpoint, Assignment.Model.preload_graph(:down)) do
      handle(
        {:assignment, signal},
        Map.merge(message, %{assignment: assignment})
      )
    end

    :ok
  end

  @impl true
  def intercept({:assignment_page_ref, _} = signal, %{assignment_page_ref: page_ref} = message) do
    assignment = Assignment.Public.get_by(page_ref, Assignment.Model.preload_graph(:down))

    dispatch!(
      {:assignment, signal},
      Map.merge(message, %{assignment: assignment})
    )

    :ok
  end

  @impl true
  def intercept({:assignment, _} = signal, message) do
    handle(signal, message)
    :ok
  end

  def intercept(
        {:consent_agreement, _} = signal,
        %{consent_agreement: consent_agreement} = message
      ) do
    if assignment =
         Assignment.Public.get_by(
           consent_agreement,
           Assignment.Model.preload_graph(:down)
         ) do
      handle(
        {:assignment, signal},
        Map.merge(message, %{assignment: assignment})
      )
    end

    :ok
  end

  def intercept({:crew_task, _} = signal, %{crew_task: %{crew_id: crew_id}} = message) do
    Assignment.Public.list_by_crew(crew_id, Assignment.Model.preload_graph(:down))
    |> Enum.each(
      &dispatch!(
        {:assignment, signal},
        Map.merge(message, %{assignment: &1})
      )
    )

    :ok
  end

  def intercept({:lab_tool, :reservations_cancelled}, %{tool: tool, user: user}) do
    # reset the membership (with new expiration time), so user has time to reserve a spot on a different time slot
    if assignment = Assignment.Public.get_by_tool(tool, [:crew]) do
      Assignment.Public.reset_member(assignment, user, dispatch: true)
    end

    :ok
  end

  def intercept({:lab_tool, :reservation_created}, %{tool: tool, user: user}) do
    if Assignment.Public.get_by_tool(tool) do
      Assignment.Public.lock_task(tool, user)
    end

    :ok
  end

  def intercept(signal, %{director: :assignment} = object) do
    handle(signal, object)
    :ok
  end

  defp handle({:assignment, event}, %{assignment: assignment, from_pid: from_pid} = message) do
    with {:workflow_item, :deleted} <- event do
      delete_crew_tasks(message)
    end

    with {:crew_task, :locked} <- event do
      %{crew_task: crew_task} = message
      Assignment.Private.log_performance_event(assignment, crew_task, :started)
    end

    with {:crew_task, :completed} <- event do
      %{crew_task: crew_task} = message
      Assignment.Private.log_performance_event(assignment, crew_task, :finished)
    end

    with {:crew_task, :accepted} <- event do
      payout_participants(message)
    end

    with {:crew_task, _} <- event do
      update_crew_task_next_action(message)
    end

    with {:crew, {:crew_member, :started}} <- event do
      %{crew_member: crew_member} = message
      Assignment.Private.log_performance_event(assignment, :started, crew_member)
    end

    with {:crew, {:crew_member, :declined}} <- event do
      %{crew_member: crew_member} = message
      Assignment.Private.log_performance_event(assignment, :declined, crew_member)
    end

    with {:crew, {:crew_member, :finished_tasks}} <- event do
      %{crew_member: crew_member} = message
      Assignment.Private.log_performance_event(assignment, :finished, crew_member)
    end

    with {:consent_agreement, {:consent_signature, :created}} <- event do
      %{consent_signature: %{user: user}} = message
      Assignment.Private.clear_performance_event(assignment, :declined, user)
      Assignment.Private.log_performance_event(assignment, :accepted, user)

      Assignment.Public.reset_member(assignment, user, dispatch: false)
    end

    update_pages(assignment, from_pid)
  end

  defp delete_crew_tasks(%{
         assignment: %Assignment.Model{crew: crew} = assignment,
         workflow_item: %Workflow.ItemModel{} = workflow_item
       }) do
    Assignment.Private.task_template(assignment, workflow_item)
    |> then(&Crew.Public.list_tasks_by_template(crew, &1))
    |> delete_crew_tasks()
  end

  defp delete_crew_tasks([_ | _] = tasks) do
    Enum.each(tasks, &Crew.Public.delete_task/1)
  end

  defp delete_crew_tasks(_), do: nil

  defp update_pages(%Assignment.Model{} = assignment, from_pid) do
    [
      Assignment.CrewPage,
      Assignment.ContentPage
    ]
    |> Enum.each(&update_page(&1, assignment, from_pid))
  end

  defp update_page(page, model, from_pid) do
    dispatch!({:page, page}, %{id: model.id, model: model, from_pid: from_pid})
  end

  defp update_crew_task_next_action(%{
         assignment: %{id: assignment_id},
         changeset: %{
           data: %{status: old_status, auth_node_id: auth_node_id},
           changes: %{status: new_status}
         }
       }) do
    users = Authorization.users_with_role(auth_node_id, :owner)

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

  defp update_crew_task_next_action(_), do: nil

  defp payout_participants(%{
         assignment: assignment,
         crew_task: crew_task,
         changeset: %{data: %{status: old_status}}
       }) do
    if old_status != :accepted do
      participants = Core.Authorization.users_with_role(crew_task, :owner)
      Enum.each(participants, &Assignment.Public.payout_participant(assignment, &1))
    end
  end
end
