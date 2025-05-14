defmodule Systems.Paper.Public do
  use Gettext, backend: CoreWeb.Gettext

  import Systems.Paper.Queries
  require Ecto.Query
  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [put_assoc: 3]

  alias Core.Repo
  alias Ecto.Changeset
  alias Ecto.Multi
  alias Frameworks.Signal
  alias Systems.Content
  alias Systems.Paper

  # Reference File

  def get_reference_file!(id, preload \\ []) do
    reference_file_query()
    |> Repo.get!(id)
    |> Repo.preload(preload)
  end

  def update!(%Paper.ReferenceFileModel{file: file} = reference_file, ref) do
    reference_file
    |> Paper.ReferenceFileModel.changeset(%{})
    |> put_assoc(:file, file |> Content.FileModel.changeset(%{ref: ref}))
    |> Repo.update!()
  end

  def mark_as_failed!(
        %Paper.ReferenceFileModel{} = reference_file,
        %Paper.RISError{message: message} = _error
      ) do
    Multi.new()
    |> Multi.update(:paper_reference_file, update_reference_file_status(reference_file, :failed))
    |> Multi.insert(
      :paper_reference_file_error,
      prepare_reference_file_error(reference_file, message)
    )
    |> Signal.Public.multi_dispatch({:paper_reference_file, :updated})
    |> Repo.transaction()
  end

  @doc """
    Creates a ReferenceFile without saving.
  """
  def prepare_reference_file(original_filename) when is_binary(original_filename) do
    prepare_reference_file(Content.Public.prepare_file(original_filename, nil))
  end

  def prepare_reference_file(%{} = content_file) do
    %Paper.ReferenceFileModel{}
    |> Paper.ReferenceFileModel.changeset(%{})
    |> put_assoc(:file, content_file)
  end

  def update_reference_file_status(reference_file, status) do
    Paper.ReferenceFileModel.changeset(reference_file, %{status: status})
  end

  def archive_reference_file!(reference_file_id) when is_integer(reference_file_id) do
    Paper.ReferenceFileModel
    |> Repo.get!(reference_file_id)
    |> Paper.ReferenceFileModel.changeset(%{status: :archived})
    |> Repo.update!()
  end

  def start_processing_reference_file(reference_file_id) when is_integer(reference_file_id) do
    %{"reference_file_id" => reference_file_id}
    |> Paper.RISProcessorJob.new()
    |> Oban.insert()
  end

  # Reference File Error

  @doc """
    Creates a ReferenceFileErrorModel without saving.
  """
  def prepare_reference_file_error(reference_file, error) do
    truncated_error = String.slice(error, 0, 255)

    %Paper.ReferenceFileErrorModel{}
    |> Paper.ReferenceFileErrorModel.changeset(%{error: truncated_error})
    |> put_assoc(:reference_file, reference_file)
  end

  # File Paper

  @doc """
    Creates a ReferenceFilePaperAssoc without saving.
  """
  def prepare_file_paper(reference_file) do
    %Paper.ReferenceFilePaperAssoc{}
    |> Paper.ReferenceFilePaperAssoc.changeset(%{})
    |> put_assoc(:reference_file, reference_file)
  end

  def finalize_file_paper(file_paper, %{paper: paper}) do
    finalize_file_paper(file_paper, paper)
  end

  def finalize_file_paper(file_paper, paper) do
    put_assoc(file_paper, :paper, paper)
  end

  # Paper

  @doc """
    Creates a PaperModel without saving.
  """
  # credo:disable-for-next-line
  def prepare_paper(
        year,
        date,
        abbreviated_journal,
        doi,
        title,
        subtitle,
        authors,
        abstract,
        keywords
      ) do
    %Paper.Model{}
    |> Paper.Model.changeset(%{
      year: year,
      date: date,
      abbreviated_journal: abbreviated_journal,
      doi: doi,
      title: title,
      subtitle: subtitle,
      authors: authors,
      abstract: abstract,
      keywords: keywords
    })
  end

  # Error

  def prepare_error({:unsupported_type_of_reference, type_of_reference}) do
    dgettext("eyra-zircon", "unsupported_type_of_reference", type: type_of_reference)
  end

  # RIS

  def prepare_ris(raw) do
    %Paper.RISModel{}
    |> Paper.RISModel.changeset(%{raw: raw})
  end

  def finalize_ris(ris, %{paper: paper}) do
    finalize_ris(ris, paper)
  end

  def finalize_ris(ris, paper) do
    Changeset.put_assoc(ris, :paper, paper)
  end
end
