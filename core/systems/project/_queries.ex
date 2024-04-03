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
end
