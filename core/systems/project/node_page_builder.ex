defmodule Systems.Project.NodePageBuilder do
  alias Frameworks.Utility.ViewModelBuilder

  alias Systems.{
    Project
  }

  def view_model(
        %{
          id: id
        },
        assigns
      ) do
    node = Project.Public.get_node!(id, Project.NodeModel.preload_graph(:down))

    item_cards = to_item_cards(node, assigns)
    node_cards = to_node_cards(node, assigns)

    %{
      id: id,
      title: node.name,
      node_cards: node_cards,
      item_cards: item_cards,
      node: node
    }
  end

  defp to_node_cards(%{children: children}, assigns) do
    Enum.map(
      children,
      &ViewModelBuilder.view_model(&1, {Project.NodePage, :node_card}, assigns)
    )
  end

  defp to_item_cards(%{items: items}, assigns) do
    items
    |> Enum.sort_by(& &1.inserted_at, {:asc, NaiveDateTime})
    |> Enum.map(&ViewModelBuilder.view_model(&1, {Project.NodePage, :item_card}, assigns))
  end
end
