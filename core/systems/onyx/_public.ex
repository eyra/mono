defmodule Systems.Onyx.Public do
  import Systems.Onyx.Queries

  alias Core.Authorization
  alias Core.Repo
  alias Systems.Content
  alias Systems.Onyx

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
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def prepare_tool_file(tool, file) do
    %Onyx.ToolFileAssociation{}
    |> Onyx.ToolFileAssociation.changeset(%{})
    |> Ecto.Changeset.put_assoc(:tool, tool)
    |> Ecto.Changeset.put_assoc(:file, file)
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
    |> Repo.all()
    |> Repo.preload(preload)
  end

  def delete_tool_file!(tool_file_id) when is_integer(tool_file_id) do
    Onyx.ToolFileAssociation
    |> Repo.get!(tool_file_id)
    |> Repo.delete!()
  end
end
