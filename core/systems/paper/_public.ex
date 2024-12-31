defmodule Systems.Paper.Public do
  import Systems.Paper.Queries
  require Ecto.Query
  import Ecto.Query, warn: false
  import CoreWeb.Gettext
  import Ecto.Changeset, only: [put_assoc: 3]

  alias Core.Repo
  alias Ecto.Changeset
  alias Systems.Content
  alias Systems.Paper

  # Reference File

  def get_reference_file!(id, preload \\ []) do
    reference_file_query()
    |> Repo.get!(id)
    |> Repo.preload(preload)
  end

  def update_reference_file!(%Paper.ReferenceFileModel{file: file} = reference_file, ref) do
    reference_file
    |> Paper.ReferenceFileModel.changeset(%{})
    |> put_assoc(:file, file |> Content.FileModel.changeset(%{ref: ref}))
    |> Repo.update!()
  end

    @doc """
    Creates a ReferenceFile without saving.
  """
  def prepare_reference_file(original_filename, url) do
    prepare_reference_file(
      Content.Public.prepare_file(original_filename, url)
    )
  end

  def prepare_reference_file(file) do
    %Paper.ReferenceFileModel{}
    |> Paper.ReferenceFileModel.changeset(%{})
    |> put_assoc(:file, file)
  end

  def archive_reference_file!(reference_file_id) when is_integer(reference_file_id) do
    Paper.ReferenceFileModel
    |> Repo.get!(reference_file_id)
    |> Paper.ReferenceFileModel.changeset(%{status: :archived})
    |> Repo.update!()
  end

  def start_processing_ris_file(reference_file_id) when is_integer(reference_file_id) do
    %{"reference_file_id" => reference_file_id}
    |> Paper.RISProcessorJob.new()
    |> Oban.insert()
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

    # File Error

  @doc """
    Creates a ReferenceFileErrorAssoc without saving.
  """
  def prepare_file_error(reference_file, error) do
    %Paper.ReferenceFileErrorAssoc{}
    |> Paper.ReferenceFileErrorAssoc.changeset(%{error: error})
    |> put_assoc(:reference_file, reference_file)
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
