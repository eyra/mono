defmodule Systems.Assignment.Switch do
  alias Systems.Project
  use Frameworks.Signal.Handler
  require Logger

  use Core, :auth

  alias Frameworks.Signal

  alias Systems.Assignment
  alias Systems.Workflow
  alias Systems.Crew
  alias Systems.NextAction

  @impl true
  def intercept(
        {:content_page, _} = signal,
        %{content_page: content_page} = message
      ) do
    if assignment =
         Assignment.Public.get_by_content_page(
           content_page,
           Assignment.Model.preload_graph(:down)
         ) do
      dispatch!(
        {:assignment, signal},
        Map.merge(message, %{assignment: assignment})
      )
    end

    :ok
  end

  @impl true
  def intercept(
        {:project_item, :inserted} = signal,
        %{project_item: %{advert: %{assignment_id: assignment_id}}} = message
      ) do
    assignment = Assignment.Public.get!(assignment_id, Assignment.Model.preload_graph(:down))

    handle(
      {:assignment, signal},
      Map.merge(message, %{assignment: assignment})
    )

    :ok
  end

  @impl true
  def intercept(
        {:project_item, :inserted} = signal,
        %{project_item: %{storage_endpoint: _} = project_item} = message
      ) do
    project_item
    |> Project.Public.get_node_by_item!()
    |> Project.Public.list_items(:assignment, Project.ItemModel.preload_graph(:down))
    |> Enum.map(& &1.assignment)
    |> Enum.each(fn assignment ->
      handle(
        {:assignment, signal},
        Map.merge(message, %{assignment: assignment})
      )
    end)

    :ok
  end

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
  def intercept(
        {:crew, event} = _signal,
        %{crew: crew, crew_member: crew_member, from_pid: from_pid} = _message
      ) do
    if assignment = Assignment.Public.get_by(crew, Assignment.Model.preload_graph(:down)) do
      case event do
        {:crew_member, :started} ->
          Assignment.Private.log_performance_event(assignment, :started, crew_member)

        {:crew_member, :declined} ->
          Assignment.Private.log_performance_event(assignment, :declined, crew_member)

        {:crew_member, :finished_tasks} ->
          Assignment.Private.log_performance_event(assignment, :finished, crew_member)
      end

      update_content_page(assignment, from_pid)
      # update only the page for the crew_member that changed
      update_crew_page(assignment, from_pid, crew_member)
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
        {:consent_agreement, {:consent_signature, :created}} = _signal,
        %{
          consent_agreement: consent_agreement,
          consent_signature: %{user: user},
          from_pid: from_pid
        } = _message
      ) do
    if assignment =
         Assignment.Public.get_by(consent_agreement, Assignment.Model.preload_graph(:down)) do
      Assignment.Private.clear_performance_event(assignment, :declined, user)
      Assignment.Private.log_performance_event(assignment, :accepted, user)
      Assignment.Public.reset_member(assignment, user, dispatch: false)

      update_content_page(assignment, from_pid)
      # update only the page for the user that accepted the consent
      update_crew_page(assignment, from_pid, user.id)
    end

    :ok
  end

  def intercept(
        {:crew_task, event} = _signal,
        %{crew_task: %{crew_id: crew_id} = crew_task, from_pid: from_pid} = message
      ) do
    Assignment.Public.list_by_crew(crew_id, Assignment.Model.preload_graph(:down))
    |> Enum.each(fn assignment ->
      case event do
        :started ->
          Assignment.Private.log_performance_event(assignment, crew_task, :started)

        :completed ->
          Assignment.Private.log_performance_event(assignment, crew_task, :finished)

        :accepted ->
          payout_participants(assignment, crew_task, message)

        :rejected ->
          nil
      end

      update_crew_task_next_action(assignment, message)

      update_content_page(assignment, from_pid)
      # update only the page for the crew_member that is the owner of the crew_task
      update_crew_page(assignment, from_pid, crew_task)
    end)

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
      Assignment.Public.start_task(tool, user)
    end

    :ok
  end

  def intercept({:zircon_screening_tool, _} = signal, %{zircon_screening_tool: tool} = message) do
    if assignment = Assignment.Public.get_by_tool(tool, Assignment.Model.preload_graph(:down)) do
      dispatch!(
        {:assignment, signal},
        Map.merge(message, %{assignment: assignment})
      )
    end

    :ok
  end

  def intercept(signal, %{director: :assignment} = object) do
    handle(signal, object)
    :ok
  end

  defp handle(
         {:assignment, :monitor_event},
         %{assignment: assignment, from_pid: from_pid} = _message
       ) do
    # Don't update the crew page here
    update_content_page(assignment, from_pid)
  end

  defp handle({:assignment, event}, %{assignment: assignment, from_pid: from_pid} = message) do
    with {:workflow_item, :deleted} <- event do
      delete_crew_tasks(message)
    end

    update_content_page(assignment, from_pid)
    # update all crew pages for the assignment
    update_crew_page(assignment, from_pid)
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

  defp update_content_page(model, from_pid) do
    dispatch!({:page, Assignment.ContentPage}, %{id: model.id, model: model, from_pid: from_pid})
  end

  defp update_crew_page(model, from_pid, %Crew.TaskModel{} = crew_task) do
    crew_member = Assignment.Public.get_member_by_task(crew_task)
    update_crew_page(model, from_pid, crew_member)
  end

  defp update_crew_page(model, from_pid, %Crew.MemberModel{user_id: user_id}) do
    update_crew_page(model, from_pid, user_id)
  end

  defp update_crew_page(model, from_pid, user_id) when is_integer(user_id) do
    dispatch!({:page, Assignment.CrewPage}, %{
      id: model.id,
      user_id: user_id,
      model: model,
      from_pid: from_pid
    })
  end

  defp update_crew_page(model, from_pid) do
    dispatch!({:page, Assignment.CrewPage}, %{id: model.id, model: model, from_pid: from_pid})
  end

  defp update_crew_task_next_action(%{id: assignment_id}, %{
         changeset: %{
           data: %{status: old_status, auth_node_id: auth_node_id},
           changes: %{status: new_status}
         }
       }) do
    users = auth_module().users_with_role(auth_node_id, :owner)

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

  defp update_crew_task_next_action(_, _), do: nil

  defp payout_participants(assignment, crew_task, %{changeset: %{data: %{status: old_status}}}) do
    if old_status != :accepted do
      participants = auth_module().users_with_role(crew_task, :owner)
      Enum.each(participants, &Assignment.Public.payout_participant(assignment, &1))
    end
  end
end
