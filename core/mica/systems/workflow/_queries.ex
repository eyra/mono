defmodule Systems.Workflow.Queries do
  require Ecto.Query
  require Frameworks.Utility.Query

  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Workflow

  def item_query() do
    from(Workflow.ItemModel, as: :item)
  end

  def item_query(%Workflow.Model{id: workflow_id}, special) when is_atom(special) do
    build(item_query(), :item, [
      workflow_id == ^workflow_id,
      tool_ref: [
        special == ^special
      ]
    ])
  end
end
