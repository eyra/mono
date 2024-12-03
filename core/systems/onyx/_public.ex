defmodule Systems.Onyx.Public do
  import Systems.Onyx.Queries

  require Ecto.Query
  import Ecto.Query, warn: false
  import CoreWeb.Gettext
  import Ecto.Changeset, only: [put_assoc: 3]

  alias Core.Authorization
  alias Core.Repo
  alias Ecto.Changeset
  alias Systems.Content
  alias Systems.Onyx

  # Tool

  def get_tool!(id, preload \\ []) do
    tool_query()
    |> Repo.get!(id)
    |> Repo.preload(preload)
  end

  @doc """
    Creates a ToolModel without saving.
  """
  def prepare_tool(attrs, auth_node \\ Authorization.prepare_node()) do
    %Onyx.ToolModel{}
    |> Onyx.ToolModel.changeset(attrs)
    |> put_assoc(:auth_node, auth_node)
  end

  # Tool File

  def get_tool_file!(id, preload \\ []) do
    tool_file_query()
    |> Repo.get!(id)
    |> Repo.preload(preload)
  end

  def update_tool_file!(%Onyx.ToolFileAssociation{file: file} = tool_file, ref) do
    tool_file
    |> Onyx.ToolFileAssociation.changeset(%{})
    |> put_assoc(:file, file |> Content.FileModel.changeset(%{ref: ref}))
    |> Repo.update!()
  end

  @doc """
    Creates a ToolFileAssociation without saving.
  """
  def prepare_tool_file(tool, file) do
    %Onyx.ToolFileAssociation{}
    |> Onyx.ToolFileAssociation.changeset(%{})
    |> put_assoc(:tool, tool)
    |> put_assoc(:file, file)
  end

  def insert_tool_file!(tool, original_filename, url) do
    Onyx.Public.prepare_tool_file(
      tool,
      Content.Public.prepare_file(original_filename, url)
    )
    |> Repo.insert!()
  end

  def list_tool_files(tool, preload \\ Onyx.ToolFileAssociation.preload_graph(:down)) do
    tool_file_query(tool)
    |> order_by([tool_file: tf], asc: tf.inserted_at)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def archive_tool_file!(tool_file_id) when is_integer(tool_file_id) do
    Onyx.ToolFileAssociation
    |> Repo.get!(tool_file_id)
    |> Onyx.ToolFileAssociation.changeset(%{status: :archived})
    |> Repo.update!()
  end

  # File Paper

  @doc """
    Creates a FilePaperAssociation without saving.
  """
  def prepare_file_paper(tool_file) do
    %Onyx.FilePaperAssociation{}
    |> Onyx.FilePaperAssociation.changeset(%{})
    |> put_assoc(:tool_file, tool_file)
  end

  def finalize_file_paper(file_paper, %{paper: paper}) do
    finalize_file_paper(file_paper, paper)
  end

  def finalize_file_paper(file_paper, paper) do
    put_assoc(file_paper, :paper, paper)
  end

  # File Error

  @doc """
    Creates a FileErrorAssociation without saving.
  """
  def prepare_file_error(tool_file, error) do
    %Onyx.FileErrorAssociation{}
    |> Onyx.FileErrorAssociation.changeset(%{error: error})
    |> put_assoc(:tool_file, tool_file)
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
    %Onyx.PaperModel{}
    |> Onyx.PaperModel.changeset(%{
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
    dgettext("eyra-onyx", "unsupported_type_of_reference", type: type_of_reference)
  end

  # RIS

  def prepare_ris(raw) do
    %Onyx.RISModel{}
    |> Onyx.RISModel.changeset(%{raw: raw})
  end

  def finalize_ris(ris, %{paper: paper}) do
    finalize_ris(ris, paper)
  end

  def finalize_ris(ris, paper) do
    Changeset.put_assoc(ris, :paper, paper)
  end
end
