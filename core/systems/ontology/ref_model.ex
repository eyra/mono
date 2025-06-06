defmodule Systems.Ontology.RefModel do
  @moduledoc """
    A module referencing a model in the Ontology.

    One of the `term` or `predicate` must be present.
  """

  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Ontology

  schema "ontology_ref" do
    belongs_to(:concept, Ontology.ConceptModel)
    belongs_to(:predicate, Ontology.PredicateModel)

    timestamps()
  end

  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          concept_id: integer() | nil,
          predicate_id: integer() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @fields ~w()a
  @required_fields ~w()a

  def changeset(ontology_ref, attrs) do
    cast(ontology_ref, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: [:concept, :predicate]

  def preload_graph(:up), do: []

  def preload_graph(:concept), do: [concept: Ontology.ConceptModel.preload_graph(:up)]
  def preload_graph(:predicate), do: [predicate: Ontology.PredicateModel.preload_graph(:up)]
end
