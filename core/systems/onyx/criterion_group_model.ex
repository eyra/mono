defmodule Systems.Onyx.CriterionGroupModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Onyx

  schema "onyx_criterion_group" do
    field(:class, Ecto.Enum, values: Onyx.CriterionClass.values())

    belongs_to(:tool, Onyx.ToolModel)
    has_many(:criteria, Onyx.CriterionModel, foreign_key: :criterion_group_id)

    timestamps()
  end

  @fields ~w(class)a
  @required_fields ~w(class)a

  def changeset(criterion_group, attrs) do
    cast(criterion_group, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([:criteria])
  def preload_graph(:up), do: preload_graph([:tool])
  def preload_graph(:tool), do: [tool: Onyx.ToolModel.preload_graph(:up)]
  def preload_graph(:criteria), do: [criteria: Onyx.CriterionModel.preload_graph(:down)]
end
