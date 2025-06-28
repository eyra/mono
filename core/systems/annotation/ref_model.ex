defmodule Systems.Annotation.RefModel do
  @moduledoc """
  A module for referencing an Annotation or Ontology Association.
  """

  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Core.Authentication
  alias Systems.Annotation
  alias Systems.Ontology

  schema "annotation_ref" do
    belongs_to(:type, Ontology.ConceptModel)

    belongs_to(:entity, Authentication.Entity)
    belongs_to(:resource, Annotation.ResourceModel)
    belongs_to(:annotation, Annotation.Model)
    belongs_to(:ontology_ref, Ontology.RefModel)

    has_many(:associations, Annotation.Assoc, foreign_key: :ref_id)

    timestamps()
  end

  @fields ~w()a
  @required_fields ~w()a
  @unique_fields ~w(type_id entity_id resource_id annotation_id ontology_ref_id)a
  @target_fields ~w(entity resource annotation ontology_ref)a

  def changeset(references, attrs) do
    references
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> unique_constraint(@unique_fields, name: :annotation_ref_unique)
  end

  # down graph
  def preload_graph(:down),
    do: preload_graph([:type, :annotation, :ontology_ref, :entity, :resource])

  def preload_graph(:type), do: [type: Ontology.ConceptModel.preload_graph(:down)]

  def preload_graph(:entity), do: [entity: []]
  def preload_graph(:resource), do: [resource: Annotation.ResourceModel.preload_graph(:down)]

  def preload_graph(:annotation),
    do: [annotation: [:entity, type: Ontology.ConceptModel.preload_graph(:down)]]

  def preload_graph(:ontology_ref), do: [ontology_ref: Ontology.RefModel.preload_graph(:down)]

  # up graph
  def preload_graph(:up), do: preload_graph([:associations])
  def preload_graph(:associations), do: [associations: Annotation.Assoc.preload_graph(:up)]

  def get_target(%__MODULE__{} = annotation_ref) when not is_nil(annotation_ref) do
    if target =
         Enum.find(@target_fields, [], fn ref ->
           not is_nil(Map.get(annotation_ref, ref))
         end) do
      Map.get(annotation_ref, target)
    else
      raise "No target found in annotation ref: #{inspect(annotation_ref)}"
    end
  end

  defimpl Systems.Ontology.Element do
    alias Systems.Ontology
    alias Systems.Annotation

    def flatten(%{type: type} = annotation_ref) do
      [annotation_ref, type] ++
        Ontology.Element.flatten(Annotation.RefModel.get_target(annotation_ref))
    end
  end
end
