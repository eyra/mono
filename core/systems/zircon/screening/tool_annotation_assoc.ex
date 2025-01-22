defmodule Systems.Zircon.Screening.ToolAnnotationAssoc do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Zircon.Screening
  alias Systems.Annotation

  schema "annotation_association" do
    belongs_to(:tool, Screening.ToolModel)
    belongs_to(:annotation, Annotation.Model)

    timestamps()
  end

  @fields ~w()a
  @required_fields @fields

  def changeset(association, attrs) do
    association
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: []

  def preload_graph(:up),
    do: [
      tool: preload_graph(:tool),
      annotation: preload_graph(:annotation)
    ]

  def preload_graph(:tool), do: [tool: Screening.ToolModel.preload_graph(:up)]
  def preload_graph(:annotation), do: [annotation: Annotation.Model.preload_graph(:up)]
end
