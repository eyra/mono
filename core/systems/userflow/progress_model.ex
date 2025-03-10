defmodule Systems.Userflow.ProgressModel do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Account.User

  schema "userflow_progress" do
    field(:visited_at, :utc_datetime)

    belongs_to(:user, User)
    belongs_to(:step, Systems.Userflow.StepModel)

    timestamps()
  end

  @fields ~w(visited_at)a
  @required_fields @fields

  def changeset(progress, attrs \\ %{}) do
    progress
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end

  def mark_visited(%__MODULE__{} = progress) do
    changeset(progress, %{
      visited_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  def preload_graph(:down), do: []
  def preload_graph(:up), do: [:user, :step]
end
