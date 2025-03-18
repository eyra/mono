defmodule Systems.Document.Public do
  use Core, :public
  import Ecto.Query, warn: false
  alias Core.Repo

  alias Systems.Document

  def get_tool!(id, preload \\ []) do
    from(tool in Document.ToolModel, preload: ^preload)
    |> Repo.get!(id)
  end

  def prepare_tool(attrs, auth_node \\ auth_module().prepare_node()) do
    %Document.ToolModel{}
    |> Document.ToolModel.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:auth_node, auth_node)
  end
end

defimpl Core.Persister, for: Systems.Document.ToolModel do
  def save(_task, changeset) do
    case Frameworks.Utility.EctoHelper.update_and_dispatch(changeset, :document_tool) do
      {:ok, %{document_tool: tool}} -> {:ok, tool}
      _ -> {:error, changeset}
    end
  end
end
