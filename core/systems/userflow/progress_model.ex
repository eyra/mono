defmodule Systems.Userflow.ProgressModel do
  @moduledoc false
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Account.User
  alias Systems.Userflow

  schema "userflow_progress" do
    belongs_to(:user, User)
    belongs_to(:step, Systems.Userflow.StepModel)

    timestamps()
  end

  @fields ~w()a
  @required_fields @fields

  def changeset(progress, attrs \\ %{}) do
    cast(progress, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([:user])
  def preload_graph(:up), do: preload_graph([:step])

  def preload_graph(:user), do: [user: []]
  def preload_graph(:step), do: [step: Userflow.StepModel.preload_graph(:up)]
end
