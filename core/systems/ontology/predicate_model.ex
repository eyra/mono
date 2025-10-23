defmodule Systems.Ontology.PredicateModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema
  import Ecto.Changeset

  alias Systems.Ontology
  alias Core.Authentication

  schema "ontology_predicate" do
    field(:type_negated?, :boolean, default: false)

    belongs_to(:entity, Authentication.Entity)

    belongs_to(:subject, Ontology.ConceptModel)
    belongs_to(:type, Ontology.ConceptModel)
    belongs_to(:object, Ontology.ConceptModel)

    timestamps()
  end

  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          type_negated?: boolean(),
          subject_id: integer() | nil,
          type_id: integer() | nil,
          object_id: integer() | nil,
          entity_id: integer() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @fields ~w(type_negated?)a
  @required_fields @fields
  @unique_fields ~w(subject_id object_id type_id entity_id type_negated?)a

  def changeset(predicate, attrs) do
    predicate
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> unique_constraint(@unique_fields, name: :ontology_predicate_unique)
    |> check_constraint(:object_id, name: :ontology_predicate_object_different_from_subject)
  end

  def preload_graph(:down), do: preload_graph([:subject, :type, :object, :entity])
  def preload_graph(:up), do: []

  def preload_graph(:subject), do: [subject: Ontology.ConceptModel.preload_graph(:down)]
  def preload_graph(:type), do: [type: Ontology.ConceptModel.preload_graph(:down)]
  def preload_graph(:object), do: [object: Ontology.ConceptModel.preload_graph(:down)]
  def preload_graph(:entity), do: [entity: []]

  defimpl Systems.Ontology.Element do
    def flatten(%{subject: subject, type: type, object: object} = predicate) do
      [predicate, subject, type, object]
    end
  end
end
