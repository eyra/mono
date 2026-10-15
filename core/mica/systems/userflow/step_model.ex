defmodule Systems.Userflow.StepModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Userflow

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

  def preload_graph(:down), do: preload_graph([:progress])
  def preload_graph(:up), do: preload_graph([:userflow])

  def preload_graph(:progress), do: [progress: Userflow.ProgressModel.preload_graph(:down)]
  def preload_graph(:userflow), do: [userflow: Userflow.Model.preload_graph(:up)]
end

defimpl Core.Persister, for: Systems.Userflow.StepModel do
  def save(_step, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :userflow_step) do
      {:ok, %{userflow_step: userflow_step}} -> {:ok, userflow_step}
      _ -> {:error, changeset}
    end
  end
end
