defmodule Systems.Onyx.CriterionModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Onyx

  schema "onxy_criterion" do
    field(:value, :string)

    belongs_to(:criterion_group, Onyx.CriterionGroupModel)
    has_many(:labels, Onyx.LabelModel, foreign_key: :criterion_id)

    timestamps()
  end

  @fields ~w(value)a
  @required_fields ~w(value)a

  def changeset(criterion, attrs) do
    cast(criterion, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([:labels])
  def preload_graph(:up), do: preload_graph([:criterion_group])

  def preload_graph(:criterion_group),
    do: [criterion_group: Onyx.CriterionGroupModel.preload_graph(:down)]

  def preload_graph(:labels), do: [labels: [:user]]
end
