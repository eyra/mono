defmodule Systems.Annotation.Model do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset

  alias Systems.Annotation
  alias Systems.Ontology
  alias Systems.Account
  
  schema "annotation" do
    field(:value, :string)
    field(:ai_generated?, :boolean)

    belongs_to(:type, Ontology.ConceptModel)
    belongs_to(:author, Account.User)
    
    many_to_many(:references, Annotation.Ref,
      join_through: Annotation.Assoc,
      join_keys: [annotation_id: :id, ref_id: :id]
    )

    timestamps()
  end

  @fields ~w(value ai_generated?)a
  @required_fields @fields
  @unique_fields ~w(value ai_generated? author_id type_id)a

  def changeset(annotation, attrs) do
    annotation
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> unique_constraint(@unique_fields, name: :annotation_unique)
  end

  def preload_graph(:down), do: [:type, :auth_node, :references]
  def preload_graph(:up), do: []

  def preload_graph(:type), do: [type: Ontology.ConceptModel.preload_graph(:down)]
  def preload_graph(:auth_node), do: [auth_node: []]
  def preload_graph(:references), do: [references: Annotation.Ref.preload_graph(:down)]
end
