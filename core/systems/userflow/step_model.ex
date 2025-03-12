defmodule Systems.Userflow.StepModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "userflow_step" do
    field(:order, :integer)
    field(:group, :string)

    belongs_to(:userflow, Systems.Userflow.Model)
    has_many(:progress, Systems.Userflow.ProgressModel, foreign_key: :step_id)

    timestamps()
  end

  @fields ~w(order group)a
  @required_fields ~w(order)a

  def changeset(step, attrs \\ %{}) do
    step
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> unique_constraint([:order, :userflow_id])
  end

  def preload_graph(:down), do: [:progress]
  def preload_graph(:up), do: [:userflow]
end
