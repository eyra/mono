defmodule Systems.Ontology.PredicateModel do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.Ontology
  alias Systems.Account

  schema "ontology_predicate" do
    field(:type_negated?, :boolean, default: false)

    belongs_to(:author, Account.User)

    belongs_to(:subject, Ontology.ConceptModel)
    belongs_to(:type, Ontology.ConceptModel)
    belongs_to(:object, Ontology.ConceptModel)

    timestamps()
  end

  @fields ~w(type_negated?)a
  @required_fields @fields
  @unique_fields ~w(subject_id object_id type_id author_id type_negated?)a

  def changeset(predicate, attrs) do
    predicate
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> unique_constraint(@unique_fields, name: :ontology_predicate_unique_predicate)
    |> check_constraint(:object_id, name: :ontology_predicate_object_different_from_subject)
  end

  def preload_graph(:down), do: []
  def preload_graph(:up), do: [:subject, :type, :object]
end