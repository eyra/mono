defmodule Systems.Project.LiveHook do
  @moduledoc "A Live Hook that injects the correct Branch (Project.NodeModel) for each Leaf"
  use Frameworks.Concept.LiveHook

  alias Frameworks.Concept
  alias Systems.Project

  @impl true
  def mount(_live_view_module, _params, _session, socket) do
    model = Map.get(socket.assigns, :model, nil)

    branch =
      with false <- model == nil,
           false <- Concept.Leaf.impl_for(model) == nil,
           item = Project.Public.get_item_by(model),
           false <- item == nil do
        node = Project.Public.get_node_by_item!(item)
        %Project.Branch{node_id: node.id, item_id: item.id}
      else
        _ -> nil
      end

    {:cont, assign(socket, branch: branch)}
  end
end
