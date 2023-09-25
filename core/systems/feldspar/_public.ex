defmodule Systems.Feldspar.Public do
  import Ecto.Query, warn: false
  alias Core.Repo

  alias Systems.{
    Feldspar
  }

  def get_tool!(id, preload \\ []) do
    from(tool in Feldspar.ToolModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def prepare_tool(attrs, auth_node \\ Core.Authorization.make_node()) do
    %Feldspar.ToolModel{}
    |> Feldspar.ToolModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end
end

defimpl Core.Persister, for: Systems.Feldspar.ToolModel do
  def save(_tool, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :feldspar_tool) do
      {:ok, %{feldspar_tool: feldspar_tool}} -> {:ok, feldspar_tool}
      _ -> {:error, changeset}
    end
  end
end
