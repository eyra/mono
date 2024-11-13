defmodule Systems.Onyx.ToolFileAssociation do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Onyx
  alias Systems.Content

  schema "onyx_tool_file" do
    belongs_to(:tool, Onyx.ToolModel)
    belongs_to(:file, Content.FileModel)
    has_many(:associated_papers, Onyx.FilePaperAssociation, foreign_key: :tool_file_id)
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

  def preload_graph(:down), do: preload_graph([:file, :associated_papers])
  def preload_graph(:up), do: preload_graph([:tool])
  def preload_graph(:tool), do: [tool: Onyx.ToolModel.preload_graph(:up)]
  def preload_graph(:file), do: [file: Content.FileModel.preload_graph(:down)]

  def preload_graph(:associated_papers),
    do: [associated_papers: Onyx.FilePaperAssociation.preload_graph(:down)]
end
