defmodule Systems.Paper.ReferenceFileModel do
  use Ecto.Schema
  use Frameworks.Utility.Schema

  import Ecto.Changeset
  alias Systems.Content
  alias Systems.Paper


  schema "paper_reference_file" do

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

    belongs_to(:file, Content.FileModel)
    has_many(:associated_papers, Paper.ReferenceFilePaperAssoc, foreign_key: :reference_file_id)
    has_many(:associated_errors, Paper.ReferenceFileErrorAssoc, foreign_key: :reference_file_id)
    timestamps()
  end

  @fields ~w(status)a

  @required_fields @fields

  def changeset(reference_file, attrs) do
    cast(reference_file, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([:file, :associated_papers, :associated_errors])
  def preload_graph(:up), do: preload_graph([])
  def preload_graph(:file), do: [file: Content.FileModel.preload_graph(:down)]

  def preload_graph(:associated_papers),
    do: [associated_papers: Paper.ReferenceFilePaperAssoc.preload_graph(:down)]

  def preload_graph(:associated_errors),
    do: [associated_errors: Paper.ReferenceFileErrorAssoc.preload_graph(:down)]
end
