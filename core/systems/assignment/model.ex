defmodule Systems.Assignment.Model do
  @moduledoc """
  The assignment type.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.{
    Assignment,
    Budget
  }

  schema "assignments" do
    belongs_to(:assignable_experiment, Assignment.ExperimentModel)
    belongs_to(:crew, Systems.Crew.Model)
    belongs_to(:budget, Budget.Model, on_replace: :update)
    belongs_to(:auth_node, Core.Authorization.Node)

    many_to_many(
      :excluded,
      Assignment.Model,
      join_through: Assignment.ExcludeModel,
      join_keys: [to_id: :id, from_id: :id],
      on_replace: :delete
    )

    field(:director, Ecto.Enum, values: [:campaign])

    timestamps()
  end

  @fields ~w()a

  defimpl Frameworks.GreenLight.AuthorizationNode do
    def id(assignment), do: assignment.auth_node_id
  end

  def changeset(assignment, nil), do: changeset(assignment, %{})

  def changeset(assignment, %Budget.Model{id: budget_id}) do
    assignment
    |> cast(%{budget_id: budget_id}, [:budget_id])
  end

  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:director])
    |> cast(attrs, @fields)
  end

  def flatten(assignment) do
    assignment
    |> Map.take([:id, :crew, :excluded, :director])
    |> Map.put(:assignable, assignable(assignment))
  end

  def assignable(%{assignable: assignable}) when not is_nil(assignable), do: assignable
  def assignable(%{assignable_experiment: assignable}) when not is_nil(assignable), do: assignable

  def assignable(%{id: id}) do
    raise "no assignable object available for assignment #{id}"
  end

  def preload_graph(:full) do
    [
      :crew,
      :excluded,
      assignable_experiment: [lab_tool: [:time_slots], survey_tool: [:auth_node]],
      budget: [:currency, :fund, :reserve]
    ]
  end

  def preload_graph(_), do: []
end
