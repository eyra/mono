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

  def create(reference_type, reference_id, auth_node) do
    attrs = %{
      reference_type: reference_type,
      reference_id: reference_id
    }

    %Crew.Model{}
    |> Crew.Model.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
    |> Repo.insert()
  end

  # Tasks

  def get_task(crew, member) do
    Repo.get_by(Crew.TaskModel, crew_id: crew.id, member_id: member.id)
  end

  def get_task!(id) do
    Repo.get!(Crew.TaskModel, id)
  end

  def create_task(crew, member, plugin) do
    attrs = %{status: :pending, plugin: plugin}

    %Crew.TaskModel{}
    |> Crew.TaskModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:crew, crew)
    |> Ecto.Changeset.put_assoc(:member, member)
    |> Repo.insert()
  end

  def create_task!(crew, member, plugin) do
    case create_task(crew, member, plugin) do
      {:ok, task} -> task
      _ -> nil
    end
  end

  def get_or_create_task(crew, member, plugin) do
    case get_task(crew, member) do
      nil -> create_task(crew, member, plugin)
      task -> {:ok, task}
    end
  end

  def get_or_create_task!(crew, member, plugin) do
    case get_or_create_task(crew, member, plugin) do
      {:ok, task} -> task
      _ -> nil
    end
  end

  def list_tasks(crew) do
    from(task in Crew.TaskModel,
      where: task.crew_id == ^crew.id
    )
    |> Repo.all()
  end

  def count_tasks(crew, status_list) do
    from(t in Crew.TaskModel,
      where: t.crew_id == ^crew.id and t.status in ^status_list,
      select: count(t.id)
    )
    |> Repo.one()
  end

  def count_pending_tasks(crew) do
    count_tasks(crew, [:pending])
  end

  def count_completed_tasks(crew) do
    count_tasks(crew, [:completed])
  end

  def setup_tasks_for_members!(members, crew, plugin) do
    members
    |> Enum.map(
      &(Crew.TaskModel.changeset(%Crew.TaskModel{}, %{status: :pending, plugin: plugin})
        |> Ecto.Changeset.put_change(:member_id, &1.id)
        |> Ecto.Changeset.put_assoc(:crew, crew))
    )
    |> Enum.map(&Repo.insert!(&1))
  end

  def complete_task!(%Crew.TaskModel{} = task) do
    task
    |> Crew.TaskModel.changeset(%{status: :completed})
    |> Repo.update!()
  end

  def delete_task(%Crew.TaskModel{} = task) do
    task
    |> Repo.delete()
  end

  def delete_task(_), do: nil


  # Members

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
      where: m.crew_id == ^crew.id and m.user_id == ^user.id,
    )
    |> Repo.one()
  end

  def get_member!(id) do
    Repo.get!(Crew.MemberModel, id)
  end

  def list_members_without_task(crew) do
    member_ids_with_task = from(t in Crew.TaskModel, where: t.crew_id == ^crew.id, select: t.member_id)

    from(m in Crew.MemberModel,
      where: m.crew_id == ^crew.id and m.id not in subquery(member_ids_with_task)
    )
    |> Repo.all()
  end

  def apply_member(%Crew.Model{} = crew, %User{} = user) do
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

  def apply_member!(%Crew.Model{} = crew, %User{} = user) do
    case Crew.Context.apply_member(crew, user) do
      {:ok, %{member: member}} -> member
      _ -> nil
    end
  end

  def list_members(%Crew.Model{} = crew) do
    from(m in Crew.MemberModel,
      where: m.crew_id == ^crew.id,
      preload: [:user]
    )
    |> Repo.all()
  end

  def withdraw_member(%Crew.Model{} = crew, %User{} = user) do
    Multi.new()
    |> Multi.delete_all(
      :member,
      from(m in Crew.MemberModel,
        where: m.crew_id == ^crew.id and m.user_id == ^user.id
      )
    )
    |> Multi.delete_all(
      :task,
      from(t in Crew.TaskModel,
        where: t.crew_id == ^crew.id
      )
    )
    |> Multi.delete_all(
      :role_assignment,
      Authorization.query_role_assignment(user, crew, :participant)
    )
    |> Repo.transaction()
  end

  @spec member?(
          atom | %{:id => any, optional(any) => any},
          atom | %{:id => any, optional(any) => any}
        ) :: boolean
  def member?(crew, user) do
    crew
    |> member_query(user)
    |> Repo.exists?()
  end

  defp member_query(crew, user) do
    from(m in Crew.MemberModel,
      where: m.crew_id == ^crew.id and m.user_id == ^user.id
    )
  end
end
