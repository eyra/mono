defmodule Systems.Ontology.ConceptModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema
  import Ecto.Changeset

  alias Core.Authentication

  schema "ontology_concept" do
    field(:phrase, :string)

    belongs_to(:entity, Authentication.Entity)

    timestamps()
  end

  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          phrase: String.t(),
          entity_id: integer() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @fields ~w(phrase)a
  @required_fields @fields

  def changeset(concept, attrs) do
    concept
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> unique_constraint(:phrase, name: :ontology_concept_unique)
  end

  def preload_graph(:down), do: preload_graph([:entity])
  def preload_graph(:up), do: []

  def preload_graph(:entity), do: [entity: []]

  defimpl Systems.Ontology.Element do
    def flatten(%{} = concept) do
      [concept]
    end
  end
end
