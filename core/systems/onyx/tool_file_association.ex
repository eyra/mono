defmodule Systems.Onyx.ToolFileAssociation do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Onyx
  alias Systems.Content

  schema "onyx_tool_file" do
    @doc """
      The status of the file in terms of processing.
      - `uploaded`: The file has been uploaded but not yet processed.
      - `processed`: The file has been successfully processed, and data has been extracted.
      - `failed`: An error occurred during the processing of the file.
      - `archived`: The file is no longer active but stored for reference.
    """
    field(:status, Ecto.Enum,
      values: [:uploaded, :processed, :failed, :archived],
      default: :uploaded
    )

    belongs_to(:tool, Onyx.ToolModel)
    belongs_to(:file, Content.FileModel)
    has_many(:associated_papers, Onyx.FilePaperAssociation, foreign_key: :tool_file_id)
    has_many(:associated_errors, Onyx.FileErrorAssociation, foreign_key: :tool_file_id)
    timestamps()
  end

  @fields ~w(status)a
  @required_fields @fields

  def changeset(tool_file, attrs) do
    cast(tool_file, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([:file, :associated_papers, :associated_errors])
  def preload_graph(:up), do: preload_graph([:tool])
  def preload_graph(:tool), do: [tool: Onyx.ToolModel.preload_graph(:up)]
  def preload_graph(:file), do: [file: Content.FileModel.preload_graph(:down)]

  def preload_graph(:associated_papers),
    do: [associated_papers: Onyx.FilePaperAssociation.preload_graph(:down)]

  def preload_graph(:associated_errors),
    do: [associated_errors: Onyx.FileErrorAssociation.preload_graph(:down)]
end
