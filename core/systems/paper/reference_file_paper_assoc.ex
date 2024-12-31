defmodule Systems.Paper.ReferenceFilePaperAssoc do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Paper

  schema "paper_reference_file_paper" do
    belongs_to(:reference_file, Paper.ReferenceFileModel)
    belongs_to(:paper, Paper.Model)
    timestamps()
  end

  @fields ~w()a
  @required_fields @fields

  def changeset(paper, attrs) do
    cast(paper, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([:paper])
  def preload_graph(:up), do: preload_graph([:reference_file])
  def preload_graph(:paper), do: [paper: Paper.Model.preload_graph(:down)]
  def preload_graph(:reference_file), do: [reference_file: Paper.ReferenceFileModel.preload_graph(:up)]
end
