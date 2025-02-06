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
  def prepare_screening_tool_reference_file(tool, original_filename)
      when is_binary(original_filename) do
    prepare_screening_tool_reference_file(
      tool,
      Paper.Public.prepare_reference_file(original_filename)
    )
  end

  def prepare_screening_tool_reference_file(tool, %{} = reference_file) do
    %Zircon.Screening.ToolReferenceFileAssoc{}
    |> Zircon.Screening.ToolReferenceFileAssoc.changeset(%{})
    |> put_assoc(:tool, tool)
    |> put_assoc(:reference_file, reference_file)
  end

  @doc """
    Inserts a new paper reference file associated with the given screening tool.
  """
  def insert_screening_tool_reference_file(tool, original_filename) do
    prepare_screening_tool_reference_file(tool, original_filename)
    |> Repo.insert!()
  end

  def insert_reference_file!(tool, original_filename) do
    %{reference_file: reference_file} =
      insert_screening_tool_reference_file(tool, original_filename)

    reference_file
  end

  def list_screening_tool_reference_files(tool) do
    screening_tool_reference_file_query(tool)
    |> Repo.all()
    |> Repo.preload(Zircon.Screening.ToolReferenceFileAssoc.preload_graph(:down))
  end

  def list_reference_files(tool) do
    list_screening_tool_reference_files(tool)
    |> Enum.map(& &1.reference_file)
  end
end
