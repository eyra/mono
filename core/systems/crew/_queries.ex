defmodule Systems.Crew.Queries do
  require Ecto.Query
  require Frameworks.Utility.Query

  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Crew
  alias CoreWeb.UI.Timestamp
  alias Core.Accounts.User
  alias Core.Authorization

  # MEMBERS

  def member_query() do
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

  def members_by_user_query(%Ecto.Query{} = users) do
    user_ids = select(users, [user: u], u.id)
    build(member_query(), :member, user: [id in subquery(user_ids)])
  end

  def members_by_task_status_query(%Crew.Model{} = crew, status_list) when is_list(status_list) do
    member_query(
      crew,
      users_by_task_status_query(status_list)
    )
    |> distinct(true)
  end

  def members_by_task_role_query(%Crew.Model{} = crew, role_list) when is_list(role_list) do
    member_query(
      crew,
      users_by_task_role_query(role_list)
    )
    |> distinct(true)
  end

  def members_by_crew_role_not_expired_query(%Crew.Model{} = crew, role_list)
      when is_list(role_list) do
    build(member_query(), :member, [
      expired == false,
      crew: [
        id == ^crew.id,
        auth_node: [
          role_assignments: [role in ^role_list]
        ]
      ]
    ])
    |> distinct(true)
  end

  def members_by_crew_role_finished_query(%Crew.Model{} = crew, role_list)
      when is_list(role_list) do
    user_ids = user_ids(users_finished_query())

    build(member_query(), :member, [
      expired == false,
      user: [id in subquery(user_ids)],
      crew: [
        id == ^crew.id,
        auth_node: [
          role_assignments: [role in ^role_list]
        ]
      ]
    ])
    |> distinct(true)
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

  # USERS

  def users_by_task_role_query(role_list) do
    build(task_query(), :task,
      auth_node: [
        role_assignments: [
          role in ^role_list
        ]
      ]
    )
    |> users_by_task_query()
  end

  def users_by_task_status_query(status_list) do
    build(task_query(), :task, [
      status in ^status_list
    ])
    |> users_by_task_query()
  end

  def users_by_task_query(%Ecto.Query{} = tasks) do
    task_ids = select(tasks, [task: t], t.id)

    from(u in User, as: :user)
    |> join(:inner, [user: u], tr in Authorization.RoleAssignment,
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

  def users_finished_query() do
    tasks_finished_query()
    |> users_by_task_query()
  end

  def user_ids(%Ecto.Query{} = users) do
    select(users, [user: u], u.id)
    |> distinct(true)
  end

  # TASKS

  def task_query() do
    from(t in Crew.TaskModel, as: :task)
  end

  def task_query(crew) do
    task_query()
    |> build(:task, [crew_id == ^crew.id])
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

  def tasks_finished_query() do
    status_list = Crew.TaskStatus.finished_states()
    build(task_query(), :task, [status in ^status_list])
  end

  def task_query_by_template(crew, task_template) when is_list(task_template) do
    task_query(crew)
    |> where([task: t], fragment("?::text[] @> ?", t.identifier, ^task_template))
  end

  def tasks_pending(task_ids) when is_list(task_ids) do
    build(task_query(), :task, [
      id in ^task_ids,
      status == :pending
    ])
  end

  def tasks_expired_pending_query(crew, expiration_timeout)
      when is_binary(expiration_timeout) do
    tasks_expired_pending_query(crew, String.to_integer(expiration_timeout))
  end

  def tasks_expired_pending_query(crew, expiration_timeout) do
    expiration_timestamp =
      Timestamp.now()
      |> Timestamp.shift_minutes(expiration_timeout * -1)

    build(task_query(crew), :task, [
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

    build(task_query(crew), :task, [
      status == :pending,
      expire_at <= ^now,
      expired == false
    ])
    |> where([task: t], not is_nil(t.started_at))
  end

  # Soft expired means: task is not marked expired but expired_at is in the past and is not started
  def tasks_soft_expired_query() do
    now = Timestamp.now()

    build(task_query(), :task, [
      expired == false,
      expire_at <= ^now,
      started_at == nil
    ])
  end
end
