defmodule Systems.Workflow.Model do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Workflow
  alias Systems.Assignment

  schema "workflows" do
    field(:type, Ecto.Enum, values: [:one, :many_optional, :many_mandatory])
    has_many(:items, Workflow.ItemModel, foreign_key: :workflow_id)
    has_one(:assignment, Assignment.Model, foreign_key: :workflow_id)
    belongs_to(:auth_node, Core.Authorization.Node)
    timestamps()
  end

  @fields ~w(type)a
  @required_fields @fields

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required(@required_fields)
  end

  def preload_graph(:down),
    do:
      preload_graph([
        :items
      ])

  def preload_graph(:items), do: [items: Workflow.ItemModel.preload_graph(:down)]

  def ready?(%{items: items}) do
    Enum.reduce(items, false, fn item, acc ->
      acc && Workflow.ItemModel.ready?(item)
    end)
  end

  def flatten(%{items: nil}), do: []

  def flatten(%{items: items}) do
    Enum.map(items, &Workflow.ItemModel.flatten/1)
  end

  def ordered_items(%Workflow.Model{items: items}) do
    Enum.sort_by(items, & &1.position)
  end
end
