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
  @target_fields ~w(concept predicate)a

  def changeset(ontology_ref, attrs) do
    cast(ontology_ref, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([:concept, :predicate])

  def preload_graph(:up), do: []

  def preload_graph(:concept), do: [concept: Ontology.ConceptModel.preload_graph(:up)]
  def preload_graph(:predicate), do: [predicate: Ontology.PredicateModel.preload_graph(:up)]

  def get_target(%Systems.Ontology.RefModel{} = ontology_ref) when not is_nil(ontology_ref) do
    if target =
         Enum.find(@target_fields, [], fn ref ->
           not is_nil(Map.get(ontology_ref, ref))
         end) do
      Map.get(ontology_ref, target)
    else
      raise "No target found in ontology_ref: #{inspect(ontology_ref)}"
    end
  end

  defimpl Systems.Ontology.Element do
    alias Systems.Ontology

    def flatten(%{} = ontology_ref) do
      [ontology_ref] ++ Ontology.Element.flatten(Ontology.RefModel.get_target(ontology_ref))
    end
  end
end
