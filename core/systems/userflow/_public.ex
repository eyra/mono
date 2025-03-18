defmodule Systems.Userflow.Public do
  import Systems.Userflow.Assembly, only: [prepare_step: 3, prepare_progress: 2]

  alias Core.Repo
  alias Ecto.Multi
  alias Frameworks.Signal
  alias Systems.Userflow
  alias Systems.Account

  def next_order(%Userflow.Model{} = userflow) do
    last_order =
      userflow
      |> Repo.preload(:steps)
      |> Map.get(:steps)
      |> Enum.map(& &1.order)
      |> Enum.max(fn -> 0 end)

    last_order + 1
  end

  @doc """
  Gets a userflow by its id.
  """
  def get_userflow!(id) do
    Userflow.Queries.get_by_id(id)
    |> Repo.one!()
  end

  def get_step!(id) do
    Repo.get!(Userflow.StepModel, id)
  end

  @doc """
  Adds a step to a userflow.
  """
  def add_step(%Userflow.Model{} = userflow, group) do
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
  def add_step(%Multi{} = multi, %Userflow.Model{} = userflow, group) do
    multi
    |> Multi.put(:next_order, next_order(userflow))
    |> Multi.insert(:step, fn %{next_order: next_order} ->
      prepare_step(userflow, next_order, group)
    end)
  end

  @doc """
  Marks a step as visited for a user.
  """
  def mark_visited(%Userflow.StepModel{} = step, %Account.User{} = user) do
    Multi.new()
    |> mark_visited(step, user)
    |> Repo.transaction()
  end

  @doc """
  Marks a step as visited for a user.
  """
  def mark_visited(%Multi{} = multi, %Userflow.StepModel{} = step, %Account.User{} = user) do
    multi
    |> Multi.put(:validate, fn _repo, _changes ->
      case Repo.get_by(Userflow.ProgressModel, user_id: user.id, step_id: step.id) do
        nil ->
          {:ok, :step_not_visited}

        _ ->
          {:error, :step_already_visited}
      end
    end)
    |> Multi.insert(:progress, prepare_progress(user, step))
    |> Signal.Public.multi_dispatch({:userflow_step, :visited})
  end

  @doc """
    Moves a step up in the userflow.
  """
  def move_step(%Userflow.StepModel{} = step, :up) do
    Multi.new()
    |> move_step(step, :up)
    |> Repo.transaction()
  end

  @doc """
    Moves a step up in the userflow.
  """
  def move_step(%Multi{} = multi, %Userflow.StepModel{} = step, :up) do
    multi
    |> Multi.run(:previous_step, fn _repo, _changes ->
      case previous_step(step) do
        nil ->
          {:error, :no_previous_step}

        previous_step ->
          {:ok, previous_step}
      end
    end)
    |> Multi.update(:previous_step_temp, fn %{previous_step: previous_step} ->
      # Use a temporary value to avoid unique constraint violation
      # First set to a negative value (assuming orders are positive)
      Userflow.StepModel.changeset(previous_step, %{order: -1})
    end)
    |> Multi.update(:userflow_step, fn %{previous_step: previous_step} ->
      Userflow.StepModel.changeset(step, %{order: previous_step.order})
    end)
    |> Multi.update(:previous_step_updated, fn %{previous_step: previous_step} ->
      Userflow.StepModel.changeset(previous_step, %{order: step.order})
    end)
    |> Signal.Public.multi_dispatch({:userflow_step, :moved_up})
  end

  @doc """
    Gets the previous step for a step or nil if there is no previous step.
  """
  def previous_step(%Userflow.StepModel{} = step) do
    case Userflow.Queries.previous_step(step) |> Repo.one() do
      nil ->
        nil

      previous_step ->
        previous_step
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
