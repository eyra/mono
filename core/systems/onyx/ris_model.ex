defmodule Systems.Onyx.RISModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Onyx

  schema "onyx_ris" do
    field(:content, :string)

    belongs_to(:paper, Onyx.PaperModel)

    timestamps()
  end

  @fields ~w(content)a
  @required_fields @fields

  def changeset(ris, attrs) do
    cast(ris, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: []
  def preload_graph(:up), do: preload_graph([:paper])
  def preload_graph(:paper), do: [paper: Onyx.PaperModel.preload_graph(:down)]
end
