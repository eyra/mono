defmodule Systems.Onyx.PaperModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Onyx

  schema "onyx_paper" do
    field(:year, :string)
    field(:date, :string)
    field(:abbreviated_journal, :string)
    field(:doi, :string)
    field(:title, :string)
    field(:subtitle, :string)
    field(:abstract, :string)
    field(:authors, {:array, :string})
    field(:keywords, {:array, :string})

    has_one(:ris, Onyx.RISModel, foreign_key: :paper_id)

    timestamps()
  end

  @fields ~w(year date abbreviated_journal doi title subtitle abstract authors keywords)a
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

  @doc """
    Generate an APA style citation for a paper. The citation will be in the format:
    [main_author] ([year]) [title] [journal] If the authors are not present, the citation will be marked with a question mark.

    This can be used as identifier for a paper. It is not guaranteed to be unique due to spelling differences in author and journal names.
  """
  def citation(%{
        authors: [main_author | _],
        year: year,
        title: title,
        abbreviated_journal: abbreviated_journal
      }) do
    "#{main_author} (#{year}) #{title} #{abbreviated_journal}"
  end

  def citation(%{authors: [], year: year, title: title, abbreviated_journal: abbreviated_journal}) do
    "? (#{year}) #{title} #{abbreviated_journal}"
  end
end
