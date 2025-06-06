defmodule Systems.Annotation.Model do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Annotation
  alias Systems.Ontology
  alias Systems.Account

  schema "annotation" do
    field(:statement, :string)
    field(:ai_generated?, :boolean)

    belongs_to(:type, Ontology.ConceptModel)
    belongs_to(:author, Account.User)

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
          ai_generated?: boolean(),
          type_id: integer() | nil,
          author_id: integer() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @fields ~w(statement ai_generated?)a
  @required_fields @fields

  def changeset(annotation, attrs) do
    annotation
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: [:type, :auth_node, :references]
  def preload_graph(:up), do: []

  def preload_graph(:type), do: [type: Ontology.ConceptModel.preload_graph(:down)]
  def preload_graph(:auth_node), do: [auth_node: []]
  def preload_graph(:references), do: [references: Annotation.RefModel.preload_graph(:down)]
end
