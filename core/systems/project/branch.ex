defmodule Systems.Project.Branch do
  use Ecto.Schema
  @primary_key false

  embedded_schema do
    field(:node_id, :integer)
    field(:item_id, :integer)
  end
end

defimpl Frameworks.Concept.Branch, for: Systems.Project.Branch do
  use CoreWeb, :verified_routes
  import CoreWeb.Gettext
  import Frameworks.Utility.List
  alias Frameworks.Concept
  alias Systems.Project

  def name(%Project.Branch{node_id: node_id}, :parent) do
    %Project.Model{name: name} =
      node_id
      |> Project.Public.get_node!()
      |> Project.Public.get_by_root()

    name
  end

  def name(%Project.Branch{item_id: item_id}, :self) do
    %Project.ItemModel{name: name} = Project.Public.get_item!(item_id)
    name
  end

  def hierarchy(%Project.Branch{node_id: node_id, item_id: item_id}) do
    node_breadcrumb = fn ->
      Project.Public.get_node!(node_id) |> breadcrumb()
    end

    item_breadcrumb = fn ->
      Project.Public.get_item!(item_id, Project.ItemModel.preload_graph(:down)) |> breadcrumb()
    end

    [root_breadcrumb()]
    |> append_if(node_breadcrumb, not is_nil(node_id))
    |> append_if(item_breadcrumb, not is_nil(item_id))
  end

  defp breadcrumb(%Project.ItemModel{name: name} = item) do
    %{label: name, path: "/#{Concept.Leaf.resource_id(item)}/content"}
  end

  defp breadcrumb(%Project.NodeModel{} = node) do
    %Project.Model{name: name} = Project.Public.get_by_root(node)
    %{label: name, path: "/project/node/#{node.id}"}
  end

  defp root_breadcrumb() do
    %{label: dgettext("eyra-project", "first.breadcrumb.label"), path: ~p"/project"}
  end
end
