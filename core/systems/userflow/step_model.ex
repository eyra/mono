defmodule Systems.Userflow.StepModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "userflow_steps" do
    field(:identifier, :string)
    field(:order, :integer)
    field(:group, :string)

    belongs_to(:userflow, Systems.Userflow.Model)
    has_many(:progress, Systems.Userflow.ProgressModel, foreign_key: :step_id)

    timestamps()
  end

  @fields ~w(identifier order group)a
  @required_fields @fields

  def changeset(step, attrs \\ %{}) do
    step
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:identifier])
    |> unique_constraint([:order])
  end

  def preload_graph(:down), do: [:progress]
  def preload_graph(:up), do: [:userflow]
end
