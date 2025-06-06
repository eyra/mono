defmodule Systems.Annotation.OntologyAssoc do
  @moduledoc """
  A module for associating an annotation with an ontology term or predicate.
  """

  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Annotation
  alias Systems.Ontology

  schema "association_ontology_assoc" do
    belongs_to(:annotation, Annotation.Model)
    belongs_to(:ontology_ref, Ontology.RefModel)

    timestamps()
  end

  @fields ~w()a
  @required_fields ~w()a

  def changeset(ontology_assoc, attrs) do
    cast(ontology_assoc, attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: [:ontology_ref]
  def preload_graph(:up), do: [:annotation]

  def preload_graph(:ontology_ref), do: [ontology_ref: Ontology.RefModel.preload_graph(:down)]
  def preload_graph(:annotation), do: [annotation: Annotation.Model.preload_graph(:up)]
end
