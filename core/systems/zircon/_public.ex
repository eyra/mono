defmodule Systems.Zircon.Public do
  import Systems.Zircon.Queries

  require Ecto.Query
  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [put_assoc: 3]

  alias Core.Authorization
  alias Core.Repo

  alias Systems.Paper
  alias Systems.Zircon

  # Screening Tool

  def get_screening_tool!(id, preload \\ []) do
    screening_tool_query()
    |> Repo.get!(id)
    |> Repo.preload(preload)
  end

  def get_screening_tool_by_reference_file!(
        %Paper.ReferenceFileModel{} = reference_file,
        preload \\ []
      ) do
    screening_tool_query(reference_file)
    |> Repo.one!()
    |> Repo.preload(preload)
  end

  @doc """
    Creates a screening tool without saving.
  """
  def prepare_screening_tool(attrs, auth_node \\ Authorization.prepare_node()) do
    %Zircon.Screening.ToolModel{}
    |> Zircon.Screening.ToolModel.changeset(attrs)
    |> put_assoc(:auth_node, auth_node)
  end

  # ReferenceFile

  @doc """
    Creates an association between the given screening tool and the paper reference file at
    the given url without saving.
  """
  def prepare_screening_tool_reference_file(tool, original_filename, url) do
    prepare_screening_tool_reference_file(
      tool,
      Paper.Public.prepare_reference_file(original_filename, url)
    )
  end

  @doc """
    Creates an association between the given screening tool and paper reference file without saving.
  """
  def prepare_screening_tool_reference_file(tool, reference_file) do
    %Zircon.Screening.ToolReferenceFileAssoc{}
    |> Zircon.Screening.ToolReferenceFileAssoc.changeset(%{})
    |> put_assoc(:tool, tool)
    |> put_assoc(:reference_file, reference_file)
  end

  @doc """
    Inserts a new paper reference file associated with the given screening tool.
  """
  def insert_screening_tool_reference_file(tool, original_filename, url) do
    prepare_screening_tool_reference_file(
      tool,
      prepare_screening_tool_reference_file(original_filename, url)
    )
    |> Repo.insert!()
  end

  def insert_reference_file!(tool, original_filename, url) do
    %{reference_file: reference_file} =
      insert_screening_tool_reference_file(tool, original_filename, url)

    reference_file
  end

  def list_screening_tool_reference_files(tool) do
    screening_tool_reference_file_query(tool)
    |> Repo.all()
    |> Repo.preload([:reference_file])
  end

  def list_reference_files(tool) do
    list_screening_tool_reference_files(tool)
    |> Enum.map(& &1.reference_file)
  end
end
