defmodule Systems.Userflow.ProgressModel do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Account.User

  schema "userflow_progress" do
    belongs_to(:user, User)
    belongs_to(:step, Systems.Userflow.StepModel)

    timestamps()
  end

  @fields ~w()a
  @required_fields @fields

  def changeset(progress, attrs \\ %{}) do
    progress
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: [:user]
  def preload_graph(:up), do: [:step]
end
