defmodule Systems.Ontology.TermModel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ontology_term" do
    field :phrase, :string

    timestamps()
  end

  @fields ~w(phrase)a
  @required_fields ~w(phrase)a

  def changeset(term, attrs) do
    term
    |> cast(attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:down), do: []
  def preload_graph(:up), do: []
end
