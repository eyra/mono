defmodule Systems.Crew.Public do
  import Ecto.Query, warn: false
  require Logger

  alias Ecto.Multi
  alias Core.Repo

  alias Core.Accounts.User
  alias Core.Authorization
  alias CoreWeb.UI.Timestamp

  alias Frameworks.{
    Signal
  }

  alias Systems.{
    Crew
  }

  def list(preload \\ [:tasks, :members]) do
    from(c in Crew.Model, preload: ^preload)
    |> Repo.all()
  end

  def get!(id, preload \\ [:tasks, :members]) do
    from(c in Crew.Model, where: c.id == ^id, preload: ^preload)
    |> Repo.one()
  end

  def prepare(auth_node, attrs \\ %{}) do
    %Crew.Model{}
    |> Crew.Model.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def active?(crew) do
    from(t in Crew.TaskModel, where: t.crew_id == ^crew.id, select: count(t.id))
    |> Repo.one() > 0
  end

  # Tasks
  def get_task(_crew, nil), do: nil

  def get_task(crew, [_ | _] = identifier) do
    from(task in Crew.TaskModel,
      where: task.crew_id == ^crew.id,
      where: task.identifier == ^identifier,
      where: task.expired == false
    )
    |> Repo.one()
  end

  def get_task!(id, preload \\ []) do
    Repo.get!(Crew.TaskModel, id) |> Repo.preload(preload)
  end

  def create_task(crew, members, identifier, expire_at \\ nil)

  def create_task(crew, [_ | _] = members, [_ | _] = identifier, expire_at) do
    attrs = %{identifier: identifier, status: :pending, expire_at: expire_at}
    user_ids = Enum.map(members, & &1.user_id)

    %Crew.TaskModel{}
    |> Crew.TaskModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:crew, crew)
    |> Ecto.Changeset.put_assoc(:auth_node, Authorization.Node.create(user_ids, :owner))
    |> Repo.insert()
  end

  def create_task(crew, member, [_ | _] = identifier, expire_at),
    do: create_task(crew, [member], identifier, expire_at)

  def create_task!(crew, members, identifier, expire_at \\ nil)

  def create_task!(crew, [_ | _] = members, [_ | _] = identifier, expire_at) do
    case create_task(crew, members, identifier, expire_at) do
      {:ok, task} -> task
      _ -> nil
    end
  end

  def create_task!(crew, member, [_ | _] = identifier, expire_at) do
    case create_task(crew, member, identifier, expire_at) do
      {:ok, task} -> task
      _ -> nil
    end
  end

  def list_tasks(crew, order_by \\ {:desc, :id}) do
    from(task in Crew.TaskModel,
      where: task.crew_id == ^crew.id,
      where: task.expired == false,
      order_by: ^order_by
    )
    |> Repo.all()
  end

  def list_tasks_for_user(crew, user_ref, order_by \\ {:desc, :id}) do
    from(t in task_query(crew, user_ref, false), order_by: ^order_by)
    |> Repo.all()
  end

  def task_query(crew, status_list, expired) when is_list(status_list) do
    from(t in Crew.TaskModel,
      where:
        t.crew_id == ^crew.id and
          t.status in ^status_list and
          t.expired == ^expired
    )
  end

  def task_query(crew, user_ref, expired) do
    user_id = user_id(user_ref)

    from(task in Crew.TaskModel,
      inner_join: node in Authorization.Node,
      on: node.id == task.auth_node_id,
      inner_join: role in Authorization.RoleAssignment,
      on: role.node_id == node.id,
      where: role.principal_id == ^user_id,
      where: role.role == :owner,
      where: task.crew_id == ^crew.id,
      where: task.expired == ^expired
    )
  end

  def task_query(crew, status_list) when is_list(status_list) do
    from(t in Crew.TaskModel,
      where:
        t.crew_id == ^crew.id and
          t.status in ^status_list
    )
  end

  def count_tasks(crew, status_list) do
    from(t in task_query(crew, status_list, false),
      select: count(t.id)
    )
    |> Repo.one()
  end

  def expired_pending_started_tasks(crew) do
    from(t in expired_pending_started_tasks_query(crew))
    |> Repo.all()
  end

  defp expired_pending_started_tasks_query(crew) do
    now = Timestamp.naive_now()

    from(t in Crew.TaskModel,
      where:
        t.crew_id == ^crew.id and
          t.status == :pending and
          t.expire_at <= ^now and
          t.expired == false and
          not is_nil(t.started_at)
    )
  end

  def completed_tasks(crew) do
    from(t in task_query(crew, [:completed]), order_by: {:desc, :completed_at})
    |> Repo.all()
  end

  def rejected_tasks(crew) do
    from(t in task_query(crew, [:rejected]), order_by: {:desc, :rejected_at})
    |> Repo.all()
  end

  def accepted_tasks(crew) do
    from(t in task_query(crew, [:accepted]), order_by: {:desc, :accepted_at})
    |> Repo.all()
  end

  def count_pending_tasks(crew) do
    from(t in task_query(crew, [:pending], false),
      select: count(t.id)
    )
    |> Repo.one()
  end

  def count_participated_tasks(crew) do
    count_tasks(crew, [:completed, :rejected, :accepted])
  end

  def cancel_task(%Crew.TaskModel{} = task) do
    update_task(task, %{started_at: nil})
  end

  def lock_task(%Crew.TaskModel{} = task) do
    update_task(task, %{started_at: Timestamp.naive_now()})
  end

  def activate_task(%Crew.TaskModel{status: status, started_at: started_at} = task) do
    timestamp = Timestamp.naive_now()

    case status do
      :pending ->
        case started_at do
          nil ->
            update_task(task, %{
              status: :completed,
              started_at: timestamp,
              completed_at: timestamp
            })

          _ ->
            update_task(task, %{status: :completed, completed_at: timestamp})
        end

      _ ->
        {:ok, %{task: task}}
    end
  end

  def activate_task!(%Crew.TaskModel{} = task) do
    case Crew.Public.activate_task(task) do
      {:ok, %{task: task}} -> task
      _ -> nil
    end
  end

  def reject_task(multi, %Crew.TaskModel{} = task, %{category: category, message: message}) do
    multi_update(multi, :task, task, %{
      status: :rejected,
      rejected_at: Timestamp.naive_now(),
      rejected_category: category,
      rejected_message: message
    })
  end

  def reject_task(multi, id, rejection) do
    task = get_task!(id)
    reject_task(multi, task, rejection)
  end

  def reject_task(%Crew.TaskModel{} = task, rejection) do
    Multi.new()
    |> reject_task(task, rejection)
    |> Repo.transaction()
  end

  def reject_task(id, rejection) do
    Multi.new()
    |> reject_task(id, rejection)
    |> Repo.transaction()
  end

  def accept_task(%Crew.TaskModel{} = task) do
    update_task(task, %{
      status: :accepted,
      accepted_at: Timestamp.naive_now()
    })
  end

  def accept_task(id) do
    get_task!(id)
    |> accept_task()
  end

  def update_task(%Crew.TaskModel{} = task, attrs) do
    Multi.new()
    |> multi_update(:task, task, attrs)
    |> Repo.transaction()
  end

  def multi_update(multi, :task, task, attrs) do
    changeset = Crew.TaskModel.changeset(task, attrs)
    multi_update(multi, :task, changeset)
  end

  def multi_update(multi, :task, changeset) do
    multi
    |> Multi.update(:task, changeset)
    |> Signal.Public.multi_dispatch({:crew_task, :updated}, changeset)
  end

  def delete_task(%Crew.TaskModel{} = task) do
    update_task(task, %{expired: true})
  end

  def delete_task(_), do: nil

  # Members
  def cancel(crew, user_ref) do
    Multi.new()
    |> cancel(crew, user_ref)
    |> Repo.transaction()
  end

  def cancel(%Multi{} = multi, crew, user_ref) do
    member = get_member(crew, user_ref)
    task_query = task_query(crew, user_ref, false)

    multi
    |> Multi.update(:member, Crew.MemberModel.changeset(member, %{expired: true}))
    |> Multi.update_all(:tasks, task_query, set: [expired: true])
  end

  def count_members(crew) do
    from(m in Crew.MemberModel,
      where: m.crew_id == ^crew.id and m.expired == false,
      select: count(m.id)
    )
    |> Repo.one()
  end

  def public_id(crew, user_ref) do
    crew
    |> member_query(user_ref)
    |> select([m], m.public_id)
    |> Repo.one()
  end

  def get_member(crew, user_ref) do
    user_id = user_id(user_ref)

    from(m in Crew.MemberModel,
      where: m.crew_id == ^crew.id and m.user_id == ^user_id and m.expired == false
    )
    |> Repo.one()
  end

  def get_member!(id) do
    Repo.get!(Crew.MemberModel, id)
  end

  def apply_member(%Crew.Model{} = crew, %User{} = user, [_ | _] = identifier, expire_at \\ nil) do
    if member = get_expired_member(crew, user, [:crew]) do
      member = reset_member(member, expire_at)
      {:ok, %{member: member}}
    else
      Multi.new()
      |> insert(:member, crew, user, %{expire_at: expire_at})
      |> insert(:task, crew, user, %{
        identifier: identifier,
        status: :pending,
        expire_at: expire_at
      })
      |> insert(:role_assignment, crew, user, :participant)
      |> Repo.transaction()
    end
  end

  defp insert(multi, :member = name, crew, %User{} = user, attrs) do
    Multi.insert(
      multi,
      name,
      %Crew.MemberModel{}
      |> Crew.MemberModel.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:crew, crew)
      |> Ecto.Changeset.put_assoc(:user, user)
    )
  end

  defp insert(multi, :role_assignment = name, crew, %User{} = user, role) do
    Multi.insert(multi, name, Authorization.build_role_assignment(user, crew, role))
  end

  defp insert(multi, :task = name, crew, %User{} = user, attrs) do
    Multi.insert(
      multi,
      name,
      %Crew.TaskModel{}
      |> Crew.TaskModel.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:crew, crew)
      |> Ecto.Changeset.put_assoc(:auth_node, Authorization.Node.create(user.id, :owner))
    )
  end

  def get_expired_member(%Crew.Model{} = crew, user_ref, preload \\ []) do
    user_id = user_id(user_ref)

    from(m in Crew.MemberModel,
      preload: ^preload,
      where:
        m.crew_id == ^crew.id and
          m.user_id == ^user_id and
          m.expired == true
    )
    |> Repo.one()
  end

  def list_members(%Crew.Model{} = crew) do
    from(m in Crew.MemberModel,
      where: m.crew_id == ^crew.id and m.expired == false,
      preload: [:user]
    )
    |> Repo.all()
  end

  def reset_member(%Crew.MemberModel{crew: crew} = member, expire_at) do
    member_query = from(m in Crew.MemberModel, where: m.id == ^member.id)
    task_query = task_query(crew, member, true)

    member_attrs = Crew.MemberModel.reset_attrs(expire_at)
    task_attrs = Crew.TaskModel.reset_attrs(expire_at)

    Multi.new()
    |> Multi.update_all(:member, member_query, set: member_attrs)
    |> Multi.update_all(:tasks, task_query, set: task_attrs)
    |> Repo.transaction()

    from(m in Crew.MemberModel, where: m.id == ^member.id)
    |> Repo.one()
  end

  def member?(crew, user_ref) do
    crew
    |> member_query(user_ref)
    |> Repo.exists?()
  end

  def expired_member?(crew, user_ref) do
    crew
    |> member_query(user_ref, true)
    |> Repo.exists?()
  end

  def subject(crew, public_id) when is_integer(public_id) do
    from(m in Crew.MemberModel,
      where:
        m.crew_id == ^crew.id and
          m.public_id == ^public_id
    )
    |> Repo.one()
  end

  def member_query(crew, user_ref, expired \\ false) do
    user_id = user_id(user_ref)

    from(m in Crew.MemberModel,
      where:
        m.crew_id == ^crew.id and
          m.user_id == ^user_id and
          m.expired == ^expired
    )
  end

  def member_query(task_ids) do
    from(member in Crew.MemberModel,
      inner_join: user in User,
      on: member.user_id == user.id,
      inner_join: role in Authorization.RoleAssignment,
      on: role.principal_id == user.id,
      inner_join: node in Authorization.Node,
      on: node.id == role.node_id,
      inner_join: task in Crew.TaskModel,
      on: task.auth_node_id == role.node_id,
      where: task.id in subquery(task_ids)
    )
  end

  @doc """
    Marks members & tasks as expired when:
    - expire_at is in the past
    - started_at is nil
  """
  def mark_expired() do
    now = Timestamp.naive_now()

    # Query expired and not started tasks. Expired, started but not completed tasks are the responsibility
    # of the researcher since surveys on third party platforms (such as Qualtrics) can have problems where
    # participants are not redirected to complete the task. This can be caused by
    #   1. bug in third party platform (not redirecting)
    #   2. no end of survey configurated (not redirecting)
    #   3. end of survey pointing to wrong url (redirecting, but to the wrong campaign)

    task_query = from(t in Crew.TaskModel, where: t.expire_at <= ^now and is_nil(t.started_at))
    task_ids = from(t in task_query, select: t.id)
    member_query = member_query(task_ids)

    Multi.new()
    |> Multi.update_all(:members, member_query, set: [expired: true])
    |> Multi.update_all(:tasks, task_query, set: [expired: true])
    |> Repo.transaction()
  end

  @doc """
    Conditionally marks tasks as expired if:
    - expire_at is in the past
    - completed_at is nil
  """
  def mark_expired(task_id) do
    now = Timestamp.naive_now()

    # Query expired, started but not completed tasks.
    task_query =
      from(t in Crew.TaskModel,
        where:
          t.id == ^task_id and
            t.expire_at <= ^now and
            is_nil(t.completed_at)
      )

    user_ids = from(t in task_query, select: t.user_id)

    member_query =
      from(m in Crew.MemberModel, where: m.expire_at <= ^now and m.user_id in subquery(user_ids))

    Multi.new()
    |> Multi.update_all(:members, member_query, set: [expired: true])
    |> Multi.update_all(:tasks, task_query, set: [expired: true])
    |> Repo.transaction()
  end

  def user_id(%User{id: id}), do: id
  def user_id(%Crew.MemberModel{user_id: id}), do: id
  def user_id(id) when is_integer(id), do: id
end
