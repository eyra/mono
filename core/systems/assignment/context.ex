defmodule Systems.Assignment.Context do
  @moduledoc """
  The assignment context.
  """

  import Ecto.Query, warn: false
  require Logger

  alias Ecto.Multi
  alias Core.Repo
  alias CoreWeb.UI.Timestamp
  alias Core.Authorization

  alias Systems.{
    Assignment,
    Crew
  }

  @min_expiration_timeout 30

  def get!(id, preload \\ []) do
    from(a in Assignment.Model, preload: ^preload)
    |> Repo.get!(id)
  end

  def get_by_crew!(%{id: crew_id}), do: get_by_crew!(crew_id)
  def get_by_crew!(crew_id) when is_number(crew_id) do
    from(a in Assignment.Model, where: a.crew_id == ^crew_id)
    |> Repo.all()
  end

  def get_by_assignable(assignable, preload \\ [])
  def get_by_assignable(%Core.Survey.Tool{id: id}, preload) do
    from(a in Assignment.Model, where: a.assignable_survey_tool_id == ^id, preload: ^preload)
    |> Repo.one()
  end

  def get_by_assignable(%Core.DataDonation.Tool{id: id}, preload) do
    from(a in Assignment.Model, where: a.assignable_data_donation_tool_id == ^id, preload: ^preload)
    |> Repo.one()
  end

  def get_by_assignable(%Core.Lab.Tool{id: id}, preload) do
    from(a in Assignment.Model, where: a.assignable_lab_tool_id == ^id, preload: ^preload)
    |> Repo.one()
  end

  def create(%{} = attrs, crew, tool, auth_node) do

    assignable_field = assignable_field(tool)

    %Assignment.Model{}
    |> Assignment.Model.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:crew, crew)
    |> Ecto.Changeset.put_assoc(assignable_field, tool)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert()
  end

  def owner(%Assignment.Model{} = assignment) do
    owner =
      assignment
      |> Authorization.get_parent_nodes()
      |> List.last()
      |> Authorization.users_with_role(:owner)
      |> List.first()

    case owner do
      nil ->
        Logger.error("No owner role found for assignment #{assignment.id}")
        {:error}
      owner ->
        {:ok, owner}
    end
  end

  defp assignable_field(%Core.Survey.Tool{}), do: :assignable_survey_tool
  defp assignable_field(%Core.Lab.Tool{}), do: :assignable_lab_tool
  defp assignable_field(%Core.DataDonation.Tool{}), do: :assignable_data_donation_tool

  def expiration_timestamp(assignment) do
    assignable = Assignment.Model.assignable(assignment)
    duration = Assignment.Assignable.duration(assignable)
    timeout = max(@min_expiration_timeout, duration)

    Timestamp.naive_from_now(timeout)
  end

  def apply_member(id, user) when is_number(id) do
    apply_member(get!(id, [:crew]), user)
  end

  def apply_member(%{crew: crew} = assignment, user) do
    if Crew.Context.member?(crew, user) do
      Crew.Context.get_member!(crew, user)
    else
      expire_at = expiration_timestamp(assignment)
      Crew.Context.apply_member!(crew, user, expire_at)
    end
  end

  def cancel(%Assignment.Model{} = assignment, user) do
    crew = get_crew(assignment)
    Crew.Context.cancel(crew, user)
  end

  def cancel(id, user) do
    get!(id) |> cancel(user)
  end

  def complete_task(%{crew: crew} = _assignment, user) do
    if Crew.Context.expired_member?(crew, user) do nil
    else
      member = Crew.Context.get_member!(crew, user)
      task = Crew.Context.get_task(crew, member)
      Crew.Context.complete_task!(task)
    end
  end

  @doc """
  How many new members can be added to the assignment?
  """
  def open_spot_count(%{crew: _crew} = assignment) do
    type = assignment_type(assignment)
    open_spot_count?(assignment, type)
  end

  @doc """
  Is assignment open for new members?
  """
  def open?(%{crew: _crew} = assignment) do
    open_spot_count(assignment) > 0
  end

  def open?(_), do: true

  defp open_spot_count?(%{crew: crew} = assignment, :one_task) do
    assignable = Assignment.Model.assignable(assignment)
    target = Assignment.Assignable.spot_count(assignable)
    all_non_expired_tasks = Crew.Context.count_tasks(crew, Crew.TaskStatus.values())

    max(0, target - all_non_expired_tasks)
  end

  defp assignment_type(_assignment) do
    # Some logic (eg: open?) is depending on the type of assignment.
    # Currently we only support the 1-task assignment: a member has one task todo.
    # Other types will be:
    #   N-tasks: a member can voluntaraly pick one or more tasks
    #   all-tasks: a member has a batch of tasks todo

    :one_task
  end

  def mark_expired_debug(%{assignable_survey_tool: %{duration: duration}} = assignment, force) do
    mark_expired_debug(assignment, duration, force)
  end

  def mark_expired_debug(%{assignable_lab_tool: tool}, _) when tool != nil, do: :noop
  def mark_expired_debug(%{assignable_donatin_tool: tool}, _) when tool != nil, do: :noop

  def mark_expired_debug(%{crew_id: crew_id}, duration, force) do
    expiration_timeout = max(@min_expiration_timeout, duration)
    task_query =
      if force do
        pending_tasks_query(crew_id)
      else
        expired_pending_tasks_query(crew_id, expiration_timeout)
      end

    member_ids = from(t in task_query, select: t.member_id)
    member_query = from(m in Crew.MemberModel, where: m.id in subquery(member_ids))

    Multi.new()
    |> Multi.update_all(:members , member_query, set: [expired: true])
    |> Multi.update_all(:tasks, task_query, set: [expired: true])
    |> Repo.transaction()
  end

  def pending_tasks_query(crew_id) do
    from(t in Crew.TaskModel,
      where:
        t.crew_id == ^crew_id and
        t.status == :pending and
        t.expired == false
    )
  end

  def expired_pending_tasks_query(crew_id, expiration_timeout) when is_binary(expiration_timeout) do
    expired_pending_tasks_query(crew_id, String.to_integer(expiration_timeout))
  end

  def expired_pending_tasks_query(crew_id, expiration_timeout) do
    expiration_timestamp =
      Timestamp.now
      |> Timestamp.shift_minutes(expiration_timeout * -1)

    from(t in Crew.TaskModel,
      where:
        t.crew_id == ^crew_id and
        t.status == :pending and
        t.expired == false and
        (
          t.started_at <= ^expiration_timestamp or
          (
            is_nil(t.started_at) and t.updated_at <= ^expiration_timestamp
          )
        )
    )
  end

  # Crew
  def get_crew(%{crew_id: crew_id} = _assignment) do
    from(
      c in Crew.Model,
      where: c.id == ^crew_id
    )
    |> Repo.one()
  end

end
