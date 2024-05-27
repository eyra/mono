defmodule Systems.Project.Queries do
  require Ecto.Query
  require Frameworks.Utility.Query

  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Project

  def item_query() do
    from(Project.ItemModel, as: :item)
  end

  def item_query(%Project.NodeModel{id: node_id}) do
    build(item_query(), :item, [
      node_id == ^node_id
    ])
  end

  def item_query_by_assignment(%Project.NodeModel{} = node, template) when is_atom(template) do
    build(item_query(node), :item,
      assignment: [
        special == ^template
      ]
    )
  end

  def item_query_by_leaderboard(%Project.NodeModel{} = node) do
    build(item_query(node), :item, leaderboard_id != nil)
  end

  def item_query_by_special(special_name, special_id) do
    special_id_field = "#{special_name}_id" |> String.to_existing_atom()

    item_query()
    |> where([item: i], field(i, ^special_id_field) == ^special_id)
  end
end
