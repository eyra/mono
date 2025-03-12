defmodule Systems.Userflow.Public do
  import Ecto.Changeset

  alias Core.Repo
  alias Ecto.Multi
  alias Systems.Userflow
  alias Systems.Account

  @doc """
  Gets a userflow by its id.
  """
  def get!(id) do
    Userflow.Queries.get_by_id(id)
    |> Repo.one!()
  end

  @doc """
    Builds a new userflow.
  """
  def build do
    %Userflow.Model{}
    |> Userflow.Model.changeset()
  end

  @doc """
  Creates a new userflow.
  """
  def create do
    build()
    |> Repo.insert()
  end

  @doc """
  Builds a new step for a userflow.
  """
  def build_step(%Userflow.Model{} = userflow, group, order)
      when is_integer(order) and is_binary(group) do
    %Userflow.StepModel{}
    |> Userflow.StepModel.changeset(%{order: order, group: group})
    |> Ecto.Changeset.put_assoc(:userflow, userflow)
  end

  @doc """
  Adds a step to a userflow.
  """
  def add_step(%Userflow.Model{} = userflow, group) when is_binary(group) do
    Multi.new()
    |> add_step(userflow, group)
    |> Repo.transaction()
    |> case do
      {:ok, %{step: step}} ->
        {:ok, step}

      {:error, changeset} ->
        {:error, changeset}

      {:error, name, _value, _changes_so_far} ->
        {:error, "Failed to add #{name}"}
    end
  end

  @doc """
    Adds a step to a userflow.
  """
  def add_step(%Multi{} = multi, %Userflow.Model{} = userflow, group) when is_binary(group) do
    multi
    |> Multi.run(:latest_order, fn _repo, _changes ->
      userflow = Repo.preload(userflow, :steps)

      {:ok,
       userflow.steps
       |> Enum.map(& &1.order)
       |> Enum.max(fn -> 0 end)}
    end)
    |> Multi.insert(:step, fn %{latest_order: latest_order} ->
      build_step(userflow, group, latest_order + 1)
    end)
  end

  def build_progress(%Account.User{} = user, %Userflow.StepModel{} = step) do
    %Userflow.ProgressModel{}
    |> Userflow.ProgressModel.changeset(%{})
    |> put_assoc(:user, user)
    |> put_assoc(:step, step)
  end

  def create_progress(%Account.User{} = user, %Userflow.StepModel{} = step) do
    Multi.new()
    |> create_progress(user, step)
    |> Repo.transaction()
  end

  def create_progress(%Multi{} = multi, %Account.User{} = user, %Userflow.StepModel{} = step) do
    multi
    |> Multi.insert(:progress, fn _ ->
      build_progress(user, step)
    end)
  end

  @doc """
  Marks a step as visited for a user.
  """
  def mark_visited(%Userflow.StepModel{} = step, %Account.User{} = user) do
    case Repo.get_by(Userflow.ProgressModel, user_id: user.id, step_id: step.id) do
      nil ->
        create_progress(user, step)

      _ ->
        raise "Step already visited"
    end
  end

  @doc """
  Gets the next unvisited step for a user in a userflow.
  """
  def next_step(%Userflow.Model{} = userflow, user_id) do
    userflow
    |> Repo.preload(steps: [:progress])
    |> Userflow.Model.next_step(user_id)
  end

  @doc """
  Checks if a user has finished all steps in a userflow.
  """
  def finished?(%Userflow.Model{} = userflow, user_id) do
    userflow
    |> Repo.preload(steps: [:progress])
    |> Userflow.Model.finished?(user_id)
  end

  @doc """
  Gets all steps in a userflow grouped by their group field.
  """
  def steps_by_group(%Userflow.Model{} = userflow) do
    userflow
    |> Userflow.Model.steps_by_group()
  end

  @doc """
  Gets all progress for a user in a userflow.
  """
  def list_progress(%Userflow.Model{} = userflow, user_id) do
    Userflow.Queries.list_progress(userflow.id, user_id)
    |> Repo.all()
  end
end
