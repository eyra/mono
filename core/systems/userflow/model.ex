defmodule Systems.Userflow.Model do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Userflow

  schema "userflow" do
    has_many(:steps, Systems.Userflow.StepModel, foreign_key: :userflow_id)

    timestamps()
  end

  @fields ~w()a
  @required_fields @fields

  def changeset(userflow, attrs \\ %{}) do
    userflow
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def finished?(%__MODULE__{steps: steps}, user_id) when is_list(steps) do
    steps
    |> Enum.sort_by(& &1.order)
    |> Enum.all?(fn step ->
      Enum.any?(step.progress, &(&1.user_id == user_id))
    end)
  end

  def next_step(%__MODULE__{steps: steps}, user_id) when is_list(steps) do
    steps
    |> Enum.sort_by(& &1.order)
    |> Enum.find(fn step ->
      not Enum.any?(step.progress, &(&1.user_id == user_id))
    end)
  end

  def steps_by_group(%__MODULE__{steps: nil}) do
    %{}
  end

  def steps_by_group(%__MODULE__{steps: steps}) when is_list(steps) do
    steps
    |> Enum.sort_by(& &1.order)
    |> Enum.group_by(& &1.group)
  end

  def preload_graph(:down), do: preload_graph([:steps])
  def preload_graph(:up), do: []

  def preload_graph(:steps), do: [steps: Userflow.StepModel.preload_graph(:down)]
end
