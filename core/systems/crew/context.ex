defmodule Systems.Crew.Context do

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Core.Repo

  alias Systems.Crew
  alias Core.Accounts.User
  alias Core.Authorization

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

  def create_task(crew, member) do
    attrs = %{status: :pending}

    %Crew.TaskModel{}
    |> Crew.TaskModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:crew, crew)
    |> Ecto.Changeset.put_assoc(:member, member)
    |> Repo.insert()
  end

  def create_task!(crew, member) do
    case create_task(crew, member) do
      {:ok, task} -> task
      _ -> nil
    end
  end

  def get_or_create_task(crew, member) do
    case get_task(crew, member) do
      nil -> create_task(crew, member)
      task -> {:ok, task}
    end
  end

  def get_or_create_task!(crew, member) do
    case get_or_create_task(crew, member) do
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

  def count_tasks(crew, status_list) do
    from(t in Crew.TaskModel,
      where:
        t.crew_id == ^crew.id and
        t.status in ^status_list and
        t.expired == false,
      select: count(t.id)
    )
    |> Repo.one()
  end

  def count_expired_pending_tasks(crew) do
    from(t in Crew.TaskModel, where: t.crew_id == ^crew.id and t.expired == true, select: count(t.id))
    |> Repo.one()
  end

  def count_pending_tasks(crew) do
    count_tasks(crew, [:pending])
  end

  def count_completed_tasks(crew) do
    count_tasks(crew, [:completed])
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

  def start_task!(%Crew.TaskModel{} = task) do
    update_task!(task,
      %{
        started_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }
    )
  end

  def complete_task!(%Crew.TaskModel{} = task) do
    update_task!(task,
      %{
        status: :completed,
        completed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }
    )
  end

  def update_task!(%Crew.TaskModel{} = task, attrs) do
    task
    |> Crew.TaskModel.changeset(attrs)
    |> Repo.update!()
  end

  def delete_task(%Crew.TaskModel{} = task) do
    update_task!(task, %{expired: true})
  end

  def delete_task(_), do: nil


  # Members

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

  def create_member(crew, user) do
    %Crew.MemberModel{}
    |> Crew.MemberModel.changeset()
    |> Ecto.Changeset.put_assoc(:crew, crew)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def get_member!(crew, user) do
    from(m in Crew.MemberModel,
      where: m.crew_id == ^crew.id and m.user_id == ^user.id and m.expired == false,
    )
    |> Repo.one()
  end

  def get_member!(id) do
    Repo.get!(Crew.MemberModel, id)
  end

  def list_members_without_task(crew) do
    member_ids_with_task = from(t in Crew.TaskModel, where: t.crew_id == ^crew.id and t.expired == false, select: t.member_id)

    from(m in Crew.MemberModel,
      where: m.crew_id == ^crew.id and m.id not in subquery(member_ids_with_task)
    )
    |> Repo.all()
  end

  def apply_member(%Crew.Model{} = crew, %User{} = user) do
    if member = get_expired_member(crew, user) do
      member = set_member_expired(member, false)
      {:ok, %{member: member}}
    else
      Multi.new()
      |> Multi.insert(
        :member,
        %Crew.MemberModel{}
        |> Crew.MemberModel.changeset()
        |> Ecto.Changeset.put_assoc(:crew, crew)
        |> Ecto.Changeset.put_assoc(:user, user)
      )
      |> Multi.insert(
        :role_assignment,
        Authorization.build_role_assignment(user, crew, :participant)
      )
      |> Repo.transaction()
    end
  end

  def apply_member!(%Crew.Model{} = crew, %User{} = user) do
    case Crew.Context.apply_member(crew, user) do
      {:ok, %{member: member}} -> member
      _ -> nil
    end
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

  def set_member_expired(%Crew.MemberModel{} = member, expired) do
    member_query = from(m in Crew.MemberModel, where: m.id == ^member.id)
    task_query = from(t in Crew.TaskModel, where: t.member_id == ^member.id)

    Multi.new()
    |> Multi.update_all(:member , member_query, set: [expired: expired])
    |> Multi.update_all(:tasks, task_query, set: [expired: expired])
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
end
