defmodule Systems.Paper.SetAssoc do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  schema "paper_set_assoc" do
    belongs_to(:paper, Systems.Paper.Model)
    belongs_to(:set, Systems.Paper.SetModel)

    timestamps()
  end

  @fields ~w()a
  @required_fields @fields

  def changeset(set_assoc, attrs) do
    cast(set_assoc, attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:up), do: []
  def preload_graph(:down), do: []
end
