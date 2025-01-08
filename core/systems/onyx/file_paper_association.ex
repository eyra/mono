defmodule Systems.Onyx.FilePaperAssociation do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Onyx

  schema "onyx_file_paper" do
    belongs_to(:tool_file, Onyx.ToolFileAssociation)
    belongs_to(:paper, Onyx.PaperModel)
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
  def preload_graph(:up), do: preload_graph([:tool_file])
  def preload_graph(:paper), do: [paper: Onyx.PaperModel.preload_graph(:down)]
  def preload_graph(:tool_file), do: [tool_file: Onyx.ToolFileAssociation.preload_graph(:up)]
end
