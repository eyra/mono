defmodule Systems.Annotation.Ref do
  @moduledoc """
  A module for referencing an Annotation or Ontology Association.
  """

  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Annotation
  alias Systems.Ontology

  schema "annotation_ref" do
    belongs_to(:type, Ontology.ConceptModel)
    belongs_to(:annotation, Annotation.Model)
    belongs_to(:ontology_ref, Ontology.Ref)

    timestamps()
  end

  @fields ~w()a
  @required_fields ~w()a

  def changeset(references, attrs) do
    references
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: [:type, :annotation, :ontology_ref]
  def preload_graph(:up), do: []

  def preload_graph(:type), do: [type: Ontology.ConceptModel.preload_graph(:down)]
  def preload_graph(:annotation), do: [annotation: Annotation.Model.preload_graph(:down)]
  def preload_graph(:ontology_ref), do: [ontology_ref: Ontology.Ref.preload_graph(:down)]
end
