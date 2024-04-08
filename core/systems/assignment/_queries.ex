defmodule Systems.Assignment.Queries do
  require Ecto.Query
  require Frameworks.Utility.Query

  import Ecto.Query, warn: false
  import Frameworks.Utility.Query, only: [build: 3]

  alias Systems.Assignment
  alias Systems.Project

  def assignment_query() do
    from(Assignment.Model, as: :assignment)
  end

  def assignment_query(special) when is_atom(special) do
    build(assignment_query(), :assignment, [
      special == ^special
    ])
  end

  def assignment_query(%Project.NodeModel{id: project_node_id}, special) do
    build(assignment_query(special), :assignment,
      project_item: [
        node: [
          id == ^project_node_id
        ]
      ]
    )
  end

  def assignment_ids(selector, special) do
    assignment_query(selector, special)
    |> select([assignment: a], a.id)
    |> distinct(true)
  end
end
