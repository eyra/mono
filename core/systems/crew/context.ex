defmodule Systems.Crew.Context do
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

  def create(auth_node, attrs \\ %{}) do
    %Crew.Model{}
    |> Crew.Model.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert()
  end

  def active?(crew) do
    from(t in Crew.TaskModel, where: t.crew_id == ^crew.id, select: count(t.id))
    |> Repo.one() > 0
  end

  # Tasks
  def get_task(_crew, nil), do: nil

  def get_task(crew, member) do
    from(task in Crew.TaskModel,
      where:
        task.crew_id == ^crew.id and
          task.member_id == ^member.id and
          task.expired == false
    )
    |> Repo.one()
  end

  def get_task!(id) do
    Repo.get!(Crew.TaskModel, id)
  end

  def create_task(crew, member, expire_at) do
    attrs = %{status: :pending, expire_at: expire_at}

    %Crew.TaskModel{}
    |> Crew.TaskModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:crew, crew)
    |> Ecto.Changeset.put_assoc(:member, member)
    |> Repo.insert()
  end

  def create_task!(crew, member, expire_at) do
    case create_task(crew, member, expire_at) do
      {:ok, task} -> task
      _ -> nil
    end
  end

  def list_tasks(crew) do
    from(task in Crew.TaskModel,
      where: task.crew_id == ^crew.id and task.expired == false
    )
    |> Repo.all()
  end

  def task_query(crew, status_list) do
    from(t in Crew.TaskModel,
      where:
        t.crew_id == ^crew.id and
          t.status in ^status_list
    )
  end

  def task_query(crew, status_list, expired) do
    from(t in Crew.TaskModel,
      where:
        t.crew_id == ^crew.id and
          t.status in ^status_list and
          t.expired == ^expired
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
    from(t in task_query(crew, [:completed]))
    |> Repo.all()
  end

  def rejected_tasks(crew) do
    from(t in task_query(crew, [:rejected]))
    |> Repo.all()
  end

  def accepted_tasks(crew) do
    from(t in task_query(crew, [:accepted]))
    |> Repo.all()
  end

  def count_started_tasks(crew) do
    from(t in task_query(crew, [:pending], false),
      where: not is_nil(t.started_at),
      select: count(t.id)
    )
    |> Repo.one()
  end

  def count_applied_tasks(crew) do
    from(t in task_query(crew, [:pending], false),
      where: is_nil(t.started_at),
      select: count(t.id)
    )
    |> Repo.one()
  end

  def count_finished_tasks(crew) do
    count_tasks(crew, [:completed, :rejected, :accepted])
  end

  def setup_tasks_for_members!(members, crew) do
    members
    |> Enum.map(
      &(Crew.TaskModel.changeset(%Crew.TaskModel{}, %{status: :pending})
        |> Ecto.Changeset.put_change(:member_id, &1.id)
        |> Ecto.Changeset.put_assoc(:crew, crew))
    )
    |> Enum.map(&Repo.insert!(&1))
  end

  def start_task(%Crew.TaskModel{} = task) do
    update_task(task, %{started_at: Timestamp.naive_now()})
  end

  def complete_task(%Crew.TaskModel{status: status} = task) do
    case status do
      :pending -> update_task(task, %{status: :completed, completed_at: Timestamp.naive_now()})
      _ -> {:ok, %{task: task}}
    end
  end

  def complete_task!(%Crew.TaskModel{} = task) do
    case Crew.Context.complete_task(task) do
      {:ok, %{task: task}} -> task
      _ -> nil
    end
  end

  def reject_task(%Crew.TaskModel{} = task, %{category: category, message: message}) do
    update_task(task, %{
      status: :rejected,
      rejected_at: Timestamp.naive_now(),
      rejected_category: category,
      rejected_message: message
    })
  end

  def reject_task(id, rejection) do
    get_task!(id)
    |> reject_task(rejection)
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
    changeset = Crew.TaskModel.changeset(task, attrs)

    Multi.new()
    |> multi_update(:task, changeset)
    |> Repo.transaction()
  end

  def multi_update(multi, :task, changeset) do
    multi
    |> Multi.update(:task, changeset)
    |> Signal.Context.multi_dispatch(:crew_task_updated, changeset)
  end

  def delete_task(%Crew.TaskModel{} = task) do
    update_task(task, %{expired: true})
  end

  def delete_task(_), do: nil

  # Members
  def cancel(crew, user) do
    if member?(crew, user) do
      member = get_member!(crew, user)
      task = get_task(crew, member)

      # temporary cancel is implemented by expiring the task
      Multi.new()
      |> Multi.update(:member, Crew.MemberModel.changeset(member, %{expired: true}))
      |> multi_update(:task, Crew.TaskModel.changeset(task, %{expired: true}))
      |> Repo.transaction()
    else
      Logger.warn("Unable to cancel, user #{user.id} is not a member on crew #{crew.id}")
    end
  end

  def count_members(crew) do
    from(m in Crew.MemberModel,
      where: m.crew_id == ^crew.id and m.expired == false,
      select: count(m.id)
    )
    |> Repo.one()
  end

  def public_id(crew, user) do
    crew
    |> member_query(user)
    |> select([m], m.public_id)
    |> Repo.one()
  end

  def get_member!(crew, user) do
    from(m in Crew.MemberModel,
      where: m.crew_id == ^crew.id and m.user_id == ^user.id and m.expired == false
    )
    |> Repo.one()
  end

  def get_member!(id) do
    Repo.get!(Crew.MemberModel, id)
  end

  def list_members_without_task(crew) do
    member_ids_with_task =
      from(t in Crew.TaskModel,
        where: t.crew_id == ^crew.id and t.expired == false,
        select: t.member_id
      )

    from(m in Crew.MemberModel,
      where: m.crew_id == ^crew.id and m.id not in subquery(member_ids_with_task)
    )
    |> Repo.all()
  end

  def apply_member!(%Crew.Model{} = crew, %User{} = user, expire_at \\ nil) do
    case Crew.Context.apply_member(crew, user, expire_at) do
      {:ok, %{member: member}} -> member
      _ -> nil
    end
  end

  def apply_member(%Crew.Model{} = crew, %User{} = user, expire_at \\ nil) do
    if member = get_expired_member(crew, user) do
      member = reset_expired_member(member, expire_at)
      {:ok, %{member: member}}
    else
      Multi.new()
      |> insert(:member, crew, user, %{expire_at: expire_at})
      |> insert(:task, crew, %{status: :pending, expire_at: expire_at})
      |> insert(:role_assignment, crew, user, :participant)
      |> Repo.transaction()
    end
  end

  defp insert(multi, :member = name, crew, user, attrs) do
    Multi.insert(
      multi,
      name,
      %Crew.MemberModel{}
      |> Crew.MemberModel.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:crew, crew)
      |> Ecto.Changeset.put_assoc(:user, user)
    )
  end

  defp insert(multi, :role_assignment = name, crew, user, role) do
    Multi.insert(multi, name, Authorization.build_role_assignment(user, crew, role))
  end

  defp insert(multi, :task = name, crew, attrs) do
    Multi.insert(multi, name, fn %{member: member} ->
      %Crew.TaskModel{}
      |> Crew.TaskModel.changeset(attrs)
      |> Ecto.Changeset.put_assoc(:crew, crew)
      |> Ecto.Changeset.put_assoc(:member, member)
    end)
  end

  def get_expired_member(%Crew.Model{} = crew, %User{} = user) do
    from(m in Crew.MemberModel,
      where:
        m.crew_id == ^crew.id and
          m.user_id == ^user.id and
          m.expired == true
    )
    |> Repo.one()
  end

  def reset_expired_member(%Crew.MemberModel{} = member, expire_at) do
    member_query = from(m in Crew.MemberModel, where: m.id == ^member.id)
    task_query = from(t in Crew.TaskModel, where: t.member_id == ^member.id)

    attrs = [expired: false, expire_at: expire_at]

    Multi.new()
    |> Multi.update_all(:member, member_query, set: attrs)
    |> Multi.update_all(:tasks, task_query, set: attrs)
    |> Repo.transaction()

    from(m in Crew.MemberModel, where: m.id == ^member.id)
    |> Repo.one()
  end

  def list_members(%Crew.Model{} = crew) do
    from(m in Crew.MemberModel,
      where: m.crew_id == ^crew.id and m.expired == false,
      preload: [:user]
    )
    |> Repo.all()
  end

  def member?(crew, user) do
    crew
    |> member_query(user)
    |> Repo.exists?()
  end

  def expired_member?(crew, user) do
    crew
    |> member_query(user, true)
    |> Repo.exists?()
  end

  defp member_query(crew, user, expired \\ false) do
    from(m in Crew.MemberModel,
      where:
        m.crew_id == ^crew.id and
          m.user_id == ^user.id and
          m.expired == ^expired
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
    member_ids = from(t in task_query, select: t.member_id)

    member_query =
      from(m in Crew.MemberModel, where: m.expire_at <= ^now and m.id in subquery(member_ids))

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

    member_ids = from(t in task_query, select: t.member_id)

    member_query =
      from(m in Crew.MemberModel, where: m.expire_at <= ^now and m.id in subquery(member_ids))

    Multi.new()
    |> Multi.update_all(:members, member_query, set: [expired: true])
    |> Multi.update_all(:tasks, task_query, set: [expired: true])
    |> Repo.transaction()
  end
end
