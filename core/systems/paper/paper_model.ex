defmodule Systems.Paper.Model do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Paper
  alias Systems.Version

  @type t :: %__MODULE__{
          doi: String.t(),
          title: String.t(),
          subtitle: String.t(),
          year: String.t(),
          date: String.t(),
          abbreviated_journal: String.t(),
          abstract: String.t(),
          authors: list(String.t()),
          keywords: list(String.t())
        }

  schema "paper" do
    field(:doi, :string)
    field(:title, :string)
    field(:subtitle, :string)
    field(:year, :string)
    field(:date, :string)
    field(:abbreviated_journal, :string)
    field(:abstract, :string)
    field(:authors, {:array, :string})
    field(:keywords, {:array, :string})

    belongs_to(:version, Version.Model)
    has_one(:ris, Paper.RISModel, foreign_key: :paper_id)

    many_to_many(:sets, Paper.SetModel,
      join_through: Paper.SetAssoc,
      join_keys: [paper_id: :id, set_id: :id],
      on_replace: :delete
    )

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

  def preload_graph(:down), do: preload_graph([:ris, :version])
  def preload_graph(:up), do: preload_graph([:sets])
  def preload_graph(:ris), do: [ris: []]
  def preload_graph(:version), do: [version: []]
  def preload_graph(:sets), do: [sets: Paper.SetModel.preload_graph(:up)]

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
