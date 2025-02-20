defmodule Systems.Crew.Public do
  use Core, :public
  require Logger

  require Ecto.Query
  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]
  import Systems.Crew.Queries

  alias Ecto.Multi
  alias Core.Repo

  alias Systems.Account.User
  alias CoreWeb.UI.Timestamp
  alias Frameworks.Signal
  alias Systems.Crew

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

  def user_finished?(crew, user_ref) do
    list_tasks_for_user(crew, user_ref)
    |> Enum.map(& &1.id)
    |> tasks_finished?()
  end

  # Tasks
  def get_task(_crew, nil), do: nil

  def get_task(crew, [_ | _] = identifier) do
    build(task_query(crew), :task, [identifier == ^identifier])
    |> Repo.one()
  end

  def get_task!(id, preload \\ []) do
    Repo.get!(Crew.TaskModel, id) |> Repo.preload(preload)
  end

  def create_task(crew, users, identifier, expire_at \\ nil)

  def create_task(crew, [_ | _] = users, [_ | _] = identifier, expire_at) do
    attrs = %{identifier: identifier, status: :pending, expire_at: expire_at}

    %Crew.TaskModel{}
    |> Crew.TaskModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:crew, crew)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_module().prepare_node(users, :owner))
    |> Repo.insert()
  end

  def create_task(crew, user, [_ | _] = identifier, expire_at),
    do: create_task(crew, [user], identifier, expire_at)

  def create_task!(crew, users, identifier, expire_at \\ nil)

  def create_task!(crew, [_ | _] = users, [_ | _] = identifier, expire_at) do
    case create_task(crew, users, identifier, expire_at) do
      {:ok, task} -> task
      _ -> nil
    end
  end

  def create_task!(crew, user, [_ | _] = identifier, expire_at) do
    case create_task(crew, user, identifier, expire_at) do
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

  def list_tasks_by_template(crew, task_template, order_by \\ {:desc, :id}) do
    from(t in task_query_by_template(crew, task_template),
      order_by: ^order_by
    )
    |> Repo.all()
  end

  def list_tasks_for_user(crew, user_ref, order_by \\ {:desc, :id}) do
    from(t in task_query(crew, user_ref, false), order_by: ^order_by)
    |> Repo.all()
  end

  def count_tasks(crew, status_list) do
    task_query(crew, status_list, false)
    |> select([task: t], count(t.id, :distinct))
    |> Repo.one()
  end

  def expired_pending_started_tasks(crew) do
    tasks_expired_pending_started_query(crew)
    |> Repo.all()
  end

  def completed_tasks(crew) do
    task_query(crew, [:completed])
    |> order_by([task: t], desc: t.completed_at)
    |> Repo.all()
  end

  def rejected_tasks(crew) do
    task_query(crew, [:rejected])
    |> order_by([task: t], desc: t.rejected_at)
    |> Repo.all()
  end

  def accepted_tasks(crew) do
    task_query(crew, [:accepted])
    |> order_by([task: t], desc: t.accepted_at)
    |> Repo.all()
  end

  def count_pending_tasks(crew) do
    task_query(crew, [:pending], false)
    |> select([task: t], count(t.id, :distinct))
    |> Repo.one()
  end

  def count_participated_tasks(crew) do
    count_tasks(crew, [:completed, :rejected, :accepted])
  end

  def cancel_task(%Crew.TaskModel{} = task) do
    update_task(task, %{started_at: nil}, :canceled)
  end

  def start_task(%Crew.TaskModel{} = task) do
    update_task(task, %{started_at: Timestamp.naive_now()}, :started)
  end

  def complete_task(%Crew.TaskModel{status: status, started_at: started_at} = task) do
    timestamp = Timestamp.naive_now()

    case status do
      :pending ->
        case started_at do
          nil ->
            update_task(
              task,
              %{
                status: :completed,
                started_at: timestamp,
                completed_at: timestamp
              },
              :completed
            )

          _ ->
            update_task(task, %{status: :completed, completed_at: timestamp}, :completed)
        end

      _ ->
        {:ok, %{crew_task: task}}
    end
  end

  def complete_task!(%Crew.TaskModel{} = task) do
    case Crew.Public.complete_task(task) do
      {:ok, %{crew_task: task}} -> task
      _ -> nil
    end
  end

  def reject_task(multi, %Crew.TaskModel{} = task, %{category: category, message: message}) do
    multi_update(
      multi,
      :task,
      task,
      %{
        status: :rejected,
        rejected_at: Timestamp.naive_now(),
        rejected_category: category,
        rejected_message: message
      },
      :rejected
    )
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
    update_task(
      task,
      %{
        status: :accepted,
        accepted_at: Timestamp.naive_now()
      },
      :accepted
    )
  end

  def accept_task(id) do
    get_task!(id)
    |> accept_task()
  end

  def update_task(%Crew.TaskModel{} = task, attrs, event) do
    Multi.new()
    |> multi_update(:task, task, attrs, event)
    |> Repo.transaction()
  end

  def multi_update(multi, :task, task, attrs, event) do
    changeset = Crew.TaskModel.changeset(task, attrs)
    multi_update(multi, :task, changeset, event)
  end

  def multi_update(multi, :task, changeset, event \\ :updated) do
    multi
    |> Multi.update(:crew_task, changeset)
    |> Signal.Public.multi_dispatch({:crew_task, event}, %{changeset: changeset})
  end

  def delete_task(%Crew.TaskModel{} = task) do
    update_task(task, %{expired: true}, :deleted)
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
    # including declined members
    members_not_expired_query(crew)
    |> select([member: m], count(m.id, :distinct))
    |> Repo.one()
  end

  def count_participants(crew) do
    # including declined members
    members_by_crew_role_not_expired_query(crew, [:participant])
    |> select([member: m], count(m.id, :distinct))
    |> Repo.one()
  end

  def count_participants_finished(crew) do
    # including declined members
    members_by_crew_role_finished_query(crew, [:participant])
    |> select([member: m], count(m.id, :distinct))
    |> Repo.one()
  end

  def public_id(crew, user_ref) do
    %{public_id: public_id} = get_member(crew, user_ref)
    public_id
  end

  def get_member!(id, preload \\ []) when is_integer(id) do
    Repo.get!(Crew.MemberModel, id) |> Repo.preload(preload)
  end

  def get_member(crew, user_ref, preload \\ []) do
    build(member_query(crew, user_ref), :member, [expired == false])
    |> Repo.one()
    |> Repo.preload(preload)
  end

  def get_member_unsafe(crew, user_ref, preload \\ []) do
    # method is unsafe since it returns members regardless their expired status
    member_query(crew, user_ref)
    |> Repo.one()
    |> Repo.preload(preload)
  end

  def apply_member(%Crew.Model{} = crew, %User{} = user, [_ | _] = identifier, expire_at \\ nil) do
    if member = get_expired_member(crew, user, [:crew]) do
      member = reset_member!(member, expire_at, dispatch: true)
      {:ok, %{member: member}}
    else
      Multi.new()
      |> insert(:member, crew, user, %{expire_at: expire_at})
      |> insert(:crew_task, crew, user, %{
        identifier: identifier,
        status: :pending,
        expire_at: expire_at
      })
      |> insert(:role_assignment, crew, user, :participant)
      |> Repo.transaction()
    end
  end

  def apply_member_with_role(
        %Crew.Model{} = crew,
        %User{} = user,
        role \\ :participant,
        expire_at \\ nil
      ) do
    if member = get_expired_member(crew, user, [:crew]) do
      member = reset_member!(member, expire_at, dispatch: true)
      {:ok, %{member: member}}
    else
      Multi.new()
      |> insert(:member, crew, user, %{expire_at: expire_at})
      |> insert(:role_assignment, crew, user, role)
      |> Repo.transaction()
    end
  end

  def expire_member(
        %Multi{} = multi,
        %Crew.MemberModel{crew: %Ecto.Association.NotLoaded{}} = member
      ) do
    expire_member(multi, Repo.preload(member, [:crew]))
  end

  def expire_member(%Multi{} = multi, %Crew.MemberModel{crew: crew} = member) do
    task_query = task_query(crew, member, false)

    multi
    |> Multi.update(
      :crew_member,
      Crew.MemberModel.changeset(member, %{expired: true})
    )
    |> Multi.update_all(:tasks, task_query, set: [expired: true])
  end

  def tasks_finished?(task_ids) when is_list(task_ids) do
    tasks_pending(task_ids)
    |> Repo.all()
    |> Enum.empty?()
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
    Multi.insert(multi, name, auth_module().build_role_assignment(user, crew, role))
  end

  defp insert(multi, :crew_task = name, crew, %User{} = user, attrs) do
    Multi.insert(
      multi,
      name,
      %Crew.TaskModel{}
      |> Crew.TaskModel.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:crew, crew)
      |> Ecto.Changeset.put_assoc(:auth_node, auth_module().prepare_node(user, :owner))
    )
  end

  def get_expired_member(%Crew.Model{} = crew, user_ref, preload \\ []) do
    member_expired_query(crew, user_ref)
    |> Repo.one()
    |> Repo.preload(preload)
  end

  def list_members(%Crew.Model{} = crew) do
    members_not_expired_query(crew)
    |> Repo.all()
    |> Repo.preload([:user])
  end

  def reset_member!(%Crew.MemberModel{} = member, expire_at, opts) do
    {:ok, %{member: member}} = reset_member(member, expire_at, opts)
    member
  end

  def reset_member(%Crew.MemberModel{} = member, expire_at, opts) do
    Multi.new()
    |> reset_member(Repo.preload(member, [:crew]), expire_at, opts)
    |> Repo.transaction()
  end

  def reset_member(
        %Multi{} = multi,
        %Crew.MemberModel{crew: %Ecto.Association.NotLoaded{}} = member,
        expire_at,
        opts
      ) do
    reset_member(multi, Repo.preload(member, [:crew]), expire_at, opts)
  end

  def reset_member(%Multi{} = multi, %Crew.MemberModel{crew: crew} = member, expire_at, opts) do
    member_changeset = Crew.MemberModel.reset(member, expire_at)
    task_attrs = Crew.TaskModel.reset_attrs(expire_at)
    task_query = task_query(crew, member, true)

    multi =
      multi
      |> Multi.update(:member, member_changeset)
      |> Multi.update_all(:tasks, task_query, set: task_attrs)

    if opts[:signal] do
      Signal.Public.multi_dispatch(multi, {:crew_member, :reset}, %{crew_member: member})
    else
      multi
    end
  end

  def member(crew, user_ref) do
    member_not_expired_query(crew, user_ref)
    |> Repo.one()
  end

  def member?(%Crew.Model{} = crew, user_ref) do
    member_not_expired_query(crew, user_ref)
    |> Repo.exists?()
  end

  def expired_member?(crew, user_ref) do
    build(member_query(crew, user_ref), :member, [expired == true])
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

  @doc """
    Marks members & tasks as expired when:
    - expire_at is in the past
    - started_at is nil
  """
  def mark_expired() do
    # Query expired and not started tasks. Expired, started but not completed tasks are the responsibility
    # of the researcher since surveys on third party platforms (such as Qualtrics) can have problems where
    # participants are not redirected to complete the task. This can be caused by
    #   1. bug in third party platform (not redirecting)
    #   2. no end of survey configurated (not redirecting)
    #   3. end of survey pointing to wrong url (redirecting, but to the wrong advert)

    tasks = tasks_soft_expired_query()
    users = users_by_task_query(tasks)
    members = members_by_user_query(users)

    Multi.new()
    |> Multi.update_all(:members, members, set: [expired: true])
    |> Multi.update_all(:tasks, tasks, set: [expired: true])
    |> Repo.transaction()
  end

  def pending_tasks_query(%Crew.Model{} = crew) do
    build(task_query(crew), :task, [expired == false, status == :pending])
  end

  def mark_expired_debug(crew, expiration_timeout, force) do
    tasks =
      if force do
        pending_tasks_query(crew)
      else
        tasks_expired_pending_query(crew, expiration_timeout)
      end

    users = users_by_task_query(tasks)
    members = members_by_user_query(users)

    Multi.new()
    |> Multi.update_all(:members, members, set: [expired: true])
    |> Multi.update_all(:tasks, tasks, set: [expired: true])
    |> Repo.transaction()
  end
end
