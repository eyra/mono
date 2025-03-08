defmodule Systems.Userflow.Public do
  alias Core.Repo
  alias Systems.Userflow.{Model, StepModel, ProgressModel, Queries}

  @doc """
  Gets a userflow by its identifier.
  """
  def get!(identifier) do
    Queries.get_by_identifier(identifier)
    |> Repo.one!()
  end

  @doc """
  Creates a new userflow.
  """
  def create(identifier, title) do
    %Model{}
    |> Model.changeset(%{identifier: identifier, title: title})
    |> Repo.insert()
  end

  @doc """
  Adds a step to a userflow.
  """
  def add_step(userflow, identifier, order, group) do
    %StepModel{}
    |> StepModel.changeset(%{
      identifier: identifier,
      order: order,
      group: group
    })
    |> Ecto.Changeset.put_assoc(:userflow, userflow)
    |> Repo.insert()
  end

  @doc """
  Marks a step as visited for a user.
  """
  def mark_visited(user_id, step_id) do
    case Repo.get_by(ProgressModel, user_id: user_id, step_id: step_id) do
      nil ->
        %ProgressModel{user_id: user_id, step_id: step_id}
        |> ProgressModel.mark_visited()
        |> Repo.insert()

      progress ->
        progress
        |> ProgressModel.mark_visited()
        |> Repo.update()
    end
  end

  @doc """
  Gets the next unvisited step for a user in a userflow.
  """
  def next_step(identifier, user_id) do
    identifier
    |> get!()
    |> Model.next_step(user_id)
  end

  @doc """
  Checks if a user has finished all steps in a userflow.
  """
  def finished?(identifier, user_id) do
    identifier
    |> get!()
    |> Model.finished?(user_id)
  end

  @doc """
  Gets all steps in a userflow grouped by their group field.
  """
  def steps_by_group(identifier) do
    identifier
    |> get!()
    |> Model.steps_by_group()
  end

  @doc """
  Gets all progress for a user in a userflow.
  """
  def get_user_progress(user_id, userflow_id) do
    Queries.get_user_progress(user_id, userflow_id)
    |> Repo.all()
  end
end
