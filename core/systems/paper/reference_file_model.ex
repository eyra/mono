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

    many_to_many(:papers, Paper.Model,
      join_through: Paper.ReferenceFilePaperAssoc,
      join_keys: [reference_file_id: :id, paper_id: :id]
    )

    has_many(:errors, Paper.ReferenceFileErrorModel, foreign_key: :reference_file_id)
    timestamps()
  end

  @type t() :: %__MODULE__{
          id: String.t(),
          status: :uploaded | :processed | :failed | :archived
        }

  @fields ~w(status)a

  @required_fields @fields

  def changeset(reference_file, attrs) do
    cast(reference_file, attrs, @fields)
  end

  def validate(changeset) do
    validate_required(changeset, @required_fields)
  end

  def preload_graph(:down), do: preload_graph([:file, :errors])
  def preload_graph(:up), do: preload_graph([])
  def preload_graph(:file), do: [file: Content.FileModel.preload_graph(:down)]

  def preload_graph(:papers),
    do: [papers: Paper.Model.preload_graph(:down)]

  def preload_graph(:errors),
    do: [errors: Paper.ReferenceFileErrorModel.preload_graph(:down)]
end
