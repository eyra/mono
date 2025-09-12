defmodule Systems.Userflow.Assembly do
  use Core, :auth
  use Gettext, backend: CoreWeb.Gettext

  import Ecto.Changeset

  alias Core.Repo
  alias Ecto.Multi
  alias Systems.Account
  alias Systems.Userflow

  @doc """
    Builds a new userflow.
  """
  def prepare_userflow() do
    %Userflow.Model{}
    |> Userflow.Model.changeset(%{})
  end

  @doc """
    Builds a new step.
  """
  def prepare_step(order, group \\ nil) when is_integer(order) do
    %Userflow.StepModel{}
    |> Userflow.StepModel.changeset(%{order: order, group: group})
  end

  @doc """
    Builds a new step with a userflow.
  """
  def prepare_step(%Userflow.Model{} = userflow, order, group) when is_integer(order) do
    %Userflow.StepModel{}
    |> Userflow.StepModel.changeset(%{order: order, group: group})
    |> put_assoc(:userflow, userflow)
  end

  @doc """
    Builds a new progress.
  """
  def prepare_progress(%Account.User{} = user, %Userflow.StepModel{} = step) do
    %Userflow.ProgressModel{}
    |> Userflow.ProgressModel.changeset(%{})
    |> put_assoc(:user, user)
    |> put_assoc(:step, step)
  end

  @doc """
  Creates a new userflow.
  """
  def create_userflow() do
    prepare_userflow()
    |> Repo.insert()
  end

  @doc """
    Creates a new progress.
  """
  def create_progress(%Account.User{} = user, %Userflow.StepModel{} = step) do
    Multi.new()
    |> create_progress(user, step)
    |> Repo.commit()
  end

  @doc """
    Creates a new progress.
  """
  def create_progress(%Multi{} = multi, %Account.User{} = user, %Userflow.StepModel{} = step) do
    multi
    |> Multi.insert(:progress, fn _ ->
      prepare_progress(user, step)
    end)
  end

  def create_userflow(%Multi{} = multi, name) do
    multi
    |> Multi.insert(name, prepare_userflow())
  end

  def create_userflow_and_step(%Multi{} = multi, userflow_name, step_name, group) do
    multi
    |> Multi.insert(userflow_name, prepare_userflow())
    |> create_first_step(step_name, userflow_name, group)
  end

  def create_first_step(%Multi{} = multi, name, userflow_name, group) do
    multi
    |> Multi.insert(name, fn state ->
      Map.get(state, userflow_name)
      |> prepare_step(0, group)
    end)
  end

  def create_next_step(%Multi{} = multi, name, userflow_name) do
    multi
    |> Multi.run(:next_order, fn _, state ->
      {
        :ok,
        Map.get(state, userflow_name) |> Userflow.Public.next_order()
      }
    end)
    |> Multi.insert(name, fn %{next_order: next_order} = state ->
      Map.get(state, userflow_name)
      |> prepare_step(next_order, nil)
    end)
  end
end
