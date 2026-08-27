defmodule Systems.Crew.Queries do
  @moduledoc false
  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Core.Authorization.RoleAssignment
  alias CoreWeb.UI.Timestamp
  # MEMBERS
  alias Systems.Account.User
  alias Systems.Crew

  require Ecto.Query
  require Frameworks.Utility.Query

  def member_query do
    from(m in Crew.MemberModel, as: :member)
  end

  def member_query(%Crew.MemberModel{id: member_id}) do
    build(member_query(), :member, [id == ^member_id])
  end

  def member_query(%Crew.Model{id: crew_id}) do
    build(member_query(), :member, crew: [id == ^crew_id])
  end

  def member_query(%Crew.Model{} = crew, %Ecto.Query{} = users) do
    user_ids = select(users, [user: u], u.id)
    build(member_query(crew), :member, user: [id in subquery(user_ids)])
  end

  def member_query(%Crew.Model{} = crew, user_ref) do
    user_id = User.user_id(user_ref)
    build(member_query(crew), :member, user: [id == ^user_id])
  end

  def members_by_task_query(%Ecto.Query{} = tasks) do
    task_ids = select(tasks, [task: t], t.id)

    member_ids =
      member_query()
      |> join(:inner, [member: m], ra in RoleAssignment,
        as: :task_role,
        on: ra.principal_id == m.user_id and ra.role == :owner
      )
      |> join(:inner, [member: m, task_role: ra], t in Crew.TaskModel,
        as: :task,
        on: t.auth_node_id == ra.node_id and t.crew_id == m.crew_id
      )
      |> where([task: t], t.id in subquery(task_ids))
      |> select([member: m], m.id)

    build(member_query(), :member, [id in subquery(member_ids)])
  end

  def members_by_task_status_query(%Crew.Model{} = crew, status_list) when is_list(status_list) do
    crew
    |> member_query(users_by_task_status_query(status_list))
    |> distinct(true)
  end

  def members_by_task_role_query(%Crew.Model{} = crew, role_list) when is_list(role_list) do
    crew
    |> member_query(users_by_task_role_query(role_list))
    |> distinct(true)
  end

  def members_by_crew_role_not_expired_query(%Crew.Model{} = crew, role_list)
      when is_list(role_list) do
    crew
    |> members_with_crew_role_query(role_list)
    |> distinct(true)
  end

  def members_by_crew_role_finished_query(%Crew.Model{} = crew, role_list)
      when is_list(role_list) do
    user_ids = user_ids(users_finished_query())

    crew
    |> members_with_crew_role_query(role_list)
    |> where([member: m], m.user_id in subquery(user_ids))
    |> distinct(true)
  end

  # Correlates each crew member to a role_assignment on the crew's auth_node
  # whose principal_id == member.user_id — so filtering by role actually filters
  # per-member, not "does the crew have any assignment with this role."
  defp members_with_crew_role_query(
         %Crew.Model{id: crew_id, auth_node_id: auth_node_id},
         role_list
       ) do
    member_query()
    |> join(:inner, [member: m], ra in RoleAssignment,
      on:
        ra.principal_id == m.user_id and ra.node_id == ^auth_node_id and
          ra.role in ^role_list,
      # USERS
      as: :role_assignment
    )
    |> where([member: m], m.crew_id == ^crew_id and m.expired == false)
  end

  def member_expired_query(%Crew.Model{} = crew, user_ref) do
    build(member_query(crew, user_ref), :member, [expired == true])
  end

  def member_not_expired_query(%Crew.Model{} = crew, user_ref) do
    build(member_query(crew, user_ref), :member, [expired == false])
  end

  def members_not_expired_query(%Crew.Model{} = crew) do
    build(member_query(crew), :member, [expired == false])
  end

  def users_by_task_role_query(role_list) do
    task_query()
    |> build(:task,
      auth_node: [
        role_assignments: [
          role in ^role_list
        ]
      ]
    )
    |> users_by_task_query()
  end

  def users_by_task_status_query(status_list) do
    task_query()
    |> build(:task, [
      status in ^status_list
    ])
    |> users_by_task_query()
  end

  def users_by_task_query(%Ecto.Query{} = tasks) do
    task_ids = select(tasks, [task: t], t.id)

    from(u in User, as: :user)
    |> join(:inner, [user: u], tr in RoleAssignment,
      # TASKS
      as: :task_role,
      on: tr.principal_id == u.id
    )
    |> join(:inner, [task_role: tr], t in Crew.TaskModel,
      as: :task,
      on: t.auth_node_id == tr.node_id
    )
    |> where([task_role: r], r.role == :owner)
    |> where([task: t], t.id in subquery(task_ids))
  end

  def users_finished_query do
    users_by_task_query(tasks_finished_query())
  end

  def user_ids(%Ecto.Query{} = users) do
    users
    |> select([user: u], u.id)
    |> distinct(true)
  end

  def task_query do
    from(t in Crew.TaskModel, as: :task)
  end

  def task_query(crew) do
    build(task_query(), :task, [crew_id == ^crew.id])
  end

  def task_query(crew, status_list) when is_list(status_list) do
    build(task_query(crew), :task, [status in ^status_list])
  end

  def task_query(crew, status_list, expired) when is_list(status_list) do
    build(task_query(crew, status_list), :task, [expired == ^expired])
  end

  def task_query(crew, user_ref, expired) do
    user_id = User.user_id(user_ref)

    build(task_query(crew), :task, [
      expired == ^expired,
      auth_node: [
        role_assignments: [
          role == :owner,
          principal_id == ^user_id
        ]
      ]
    ])
  end

  def tasks_finished_query do
    status_list = Crew.TaskStatus.finished_states()
    build(task_query(), :task, [status in ^status_list])
  end

  def task_counts_by_user_query(%Crew.Model{id: crew_id}, status_list)
      when is_list(status_list) do
    from(task in Crew.TaskModel,
      as: :task,
      join: node in assoc(task, :auth_node),
      as: :auth_node,
      join: role in assoc(node, :role_assignments),
      as: :role_assignments,
      where:
        task.crew_id == ^crew_id and task.expired == false and task.status in ^status_list and
          role.role == :owner,
      group_by: role.principal_id,
      select: {role.principal_id, count(task.id, :distinct)}
    )
  end

  def task_query_by_template(crew, task_template) when is_list(task_template) do
    crew
    |> task_query()
    |> where([task: t], fragment("?::text[] @> ?", t.identifier, ^task_template))
  end

  def tasks_pending(task_ids) when is_list(task_ids) do
    build(task_query(), :task, [
      id in ^task_ids,
      status == :pending
    ])
  end

  def tasks_expired_pending_query(crew, expiration_timeout) when is_binary(expiration_timeout) do
    tasks_expired_pending_query(crew, String.to_integer(expiration_timeout))
  end

  def tasks_expired_pending_query(crew, expiration_timeout) do
    expiration_timestamp = Timestamp.shift_minutes(Timestamp.now(), expiration_timeout * -1)

    crew
    |> task_query()
    |> build(:task, [
      expired == false,
      status == :pending
    ])
    |> where(
      [task: t],
      t.started_at <= ^expiration_timestamp or
        (is_nil(t.started_at) and t.updated_at <= ^expiration_timestamp)
    )
  end

  def tasks_expired_pending_started_query(crew) do
    now = Timestamp.naive_now()

    crew
    |> task_query()
    |> build(:task, [
      status == :pending,
      expire_at <= ^now,
      expired == false
    ])
    |> where([task: t], not is_nil(t.started_at))
  end

  # Soft expired means: task is not marked expired but expired_at is in the past and is not started
  def tasks_soft_expired_query do
    now = Timestamp.now()

    build(task_query(), :task, [
      expired == false,
      expire_at <= ^now,
      started_at == nil
    ])
  end
end
