defmodule Systems.Annotation.Model do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Core.Authentication
  alias Systems.Annotation
  alias Systems.Ontology

  schema "annotation" do
    field(:statement, :string)

    belongs_to(:type, Ontology.ConceptModel)
    belongs_to(:entity, Authentication.Entity)

    many_to_many(:references, Annotation.RefModel,
      join_through: Annotation.Assoc,
      join_keys: [annotation_id: :id, ref_id: :id]
    )

    timestamps()
  end

  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          statement: String.t(),
          type_id: integer() | nil,
          entity_id: integer() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @fields ~w(statement)a
  @required_fields @fields

  def changeset(annotation, attrs) do
    annotation
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: preload_graph([:type, :entity, :references])
  def preload_graph(:up), do: []

  def preload_graph(:type), do: [type: Ontology.ConceptModel.preload_graph(:down)]
  def preload_graph(:entity), do: [entity: []]
  def preload_graph(:references), do: [references: Annotation.RefModel.preload_graph(:down)]

  defimpl Systems.Ontology.Element do
    # TODO: add limits to the depth of the graph to avoid deep graphs and infinite recursion
    def flatten(%{type: type, references: references} = annotation) do
      Enum.reduce(references, [annotation, type], fn ref, acc ->
        acc ++ Systems.Ontology.Element.flatten(ref)
      end)
    end
  end
end
