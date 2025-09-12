defmodule Systems.Paper.SetModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  alias Systems.Paper

  schema "paper_set" do
    # free-form category
    field(:category, Ecto.Atom)
    # identifier within category
    field(:identifier, :integer)

    many_to_many(:papers, Systems.Paper.Model,
      join_through: Systems.Paper.SetAssoc,
      join_keys: [set_id: :id, paper_id: :id],
      on_replace: :delete
    )

    timestamps()
  end

  @fields ~w(category identifier)a
  @required_fields @fields

  def changeset(set, attrs) do
    cast(set, attrs, @fields)
  end

  def validate(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  def preload_graph(:up), do: []
  def preload_graph(:down), do: preload_graph([:papers])

  def preload_graph(:papers), do: [papers: Paper.Model.preload_graph(:down)]
end
