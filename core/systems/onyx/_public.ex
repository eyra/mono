defmodule Systems.Onyx.Public do
  import Systems.Onyx.Queries

  alias Core.Authorization
  alias Core.Repo
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
end
