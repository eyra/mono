defmodule Systems.Project.BranchPlug do
  @behaviour Plug
  alias Frameworks.Concept
  alias Systems.Project
  alias Systems.Storage
  alias Systems.Assignment

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%{request_path: request_path} = conn, _opts) do
    branch = branch(Path.split(request_path))
    conn |> Plug.Conn.assign(:branch, branch)
  end

  defp branch(["/", "storage", "endpoint", id | _]), do: branch(Storage.Public.get_endpoint!(id))

  defp branch(["/", "assignment", "callback", workflow_item_id | _]),
    do: branch(Assignment.Public.get_by_workflow_item_id(workflow_item_id))

  defp branch(["/", "assignment", id | _]), do: branch(Assignment.Public.get(id))

  defp branch(%{} = leaf) do
    with false <- Concept.Leaf.impl_for(leaf) == nil,
         item <- Project.Public.get_item_by(leaf),
         false <- item == nil,
         node <- Project.Public.get_node_by_item!(item) do
      %Project.Branch{node_id: node.id, item_id: item.id}
    else
      _ -> nil
    end
  end

  defp branch(_), do: nil
end
