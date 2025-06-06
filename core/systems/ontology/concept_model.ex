defmodule Systems.Ontology.ConceptModel do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Account

  schema "ontology_concept" do
    field(:phrase, :string)

    belongs_to(:author, Account.User)

    timestamps()
  end

  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          phrase: String.t(),
          author_id: integer() | nil,
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

  def preload_graph(:down), do: []
  def preload_graph(:up), do: []
end
