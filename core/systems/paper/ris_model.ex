defmodule Systems.Paper.RISModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Paper

  schema "paper_ris" do
    field(:raw, :string)
    belongs_to(:paper, Paper.Model)

    timestamps()
  end

  @fields ~w(raw)a
  @required_fields @fields

  def changeset(ris, attrs) do
    cast(ris, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: []
  def preload_graph(:up), do: preload_graph([:paper])
  def preload_graph(:paper), do: [paper: Paper.Model.preload_graph(:up)]
end
