defmodule Systems.Feldspar.Public do
  use Core, :public
  import Ecto.Query, warn: false
  alias Core.Repo

  alias Systems.{
    Feldspar
  }

  import Feldspar.Private, only: [get_backend: 0]

  def get_tool!(id, preload \\ []) do
    from(tool in Feldspar.ToolModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def prepare_tool(attrs, auth_node \\ auth_module().prepare_node()) do
    %Feldspar.ToolModel{}
    |> Feldspar.ToolModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end

  def store(zip_file, original_filename) do
    get_backend().store(zip_file, original_filename)
  end

  def get_public_url(id) do
    get_backend().get_public_url(id)
  end

  def remove(id) do
    get_backend().remove(id)
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
