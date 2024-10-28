defmodule Systems.Onyx.PaperModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Onyx

  schema "onyx_paper" do
    field(:year, :integer)
    field(:journal, :string)
    field(:doi, :string)
    field(:title, :string)
    field(:abstract, :string)
    field(:authors, {:array, :string})
    field(:keywords, {:array, :string})

    belongs_to(:tool, Onyx.ToolModel)
    has_one(:ris, Onyx.RISModel, foreign_key: :paper_id)

    timestamps()
  end

  @fields ~w(year journal doi title abstract authors keywords)a
  @required_fields @fields

  def changeset(paper, attrs) do
    cast(paper, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([:ris])
  def preload_graph(:up), do: preload_graph([:tool])
  def preload_graph(:tool), do: [tool: Onyx.ToolModel.preload_graph(:up)]
  def preload_graph(:ris), do: [ris: []]
end
