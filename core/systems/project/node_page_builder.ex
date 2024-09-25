defmodule Systems.Project.NodePageBuilder do
  use Core.FeatureFlags

  alias Frameworks.Utility.ViewModelBuilder
  alias Frameworks.Concept
  alias Systems.Project

  def view_model(
        %Project.NodeModel{
          id: id
        } = node,
        assigns
      ) do
    branch = %Project.Branch{node_id: node.id}
    breadcrumbs = Concept.Branch.hierarchy(branch)
    item_cards = to_item_cards(node, assigns)
    node_cards = to_node_cards(node, assigns)

    %{
      id: id,
      title: node.name,
      breadcrumbs: breadcrumbs,
      active_menu_item: :projects,
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
    |> Enum.filter(&item_feature_enabled?/1)
    |> Enum.sort_by(& &1.inserted_at, {:asc, NaiveDateTime})
    |> Enum.map(&ViewModelBuilder.view_model(&1, {Project.NodePage, :item_card}, assigns))
  end

  defp item_feature_enabled?(%{leaderboard_id: leaderboard_id}) when not is_nil(leaderboard_id) do
    feature_enabled?(:leaderboard)
  end

  defp item_feature_enabled?(_), do: true
end
