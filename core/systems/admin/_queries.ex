defmodule Systems.Admin.Queries do
  require Ecto.Query
  import Ecto.Query, warn: false

  alias Core.Authorization.RoleAssignment
  alias Systems.Account
  alias Systems.Assignment
  alias Systems.Project

  @doc """
  Maps every project assignment to its client: one row `%{assignment_id, client_id}`.

  This is the only place that decides who the client of an assignment is, so the
  Client activity tab can move from users to organisations by changing this query.

  The client is the first (original) owner of the assignment's project: the
  project's creator. Assignments whose project has no owner left are not mapped.

  Only items on a project's root node are counted; no code creates nested
  project nodes today.

  Pass an assignment id to map only that assignment.
  """
  def assignment_client_query(assignment_id \\ nil) do
    from(assignment in Assignment.Model,
      as: :assignment,
      join: item in Project.ItemModel,
      on: item.assignment_id == assignment.id,
      join: project in Project.Model,
      on: project.root_id == item.node_id,
      join: project_owner in subquery(first_owner_per_node_query()),
      on: project_owner.node_id == project.auth_node_id,
      select: %{assignment_id: assignment.id, client_id: project_owner.principal_id}
    )
    |> only_assignment(assignment_id)
  end

  defp only_assignment(query, nil), do: query

  defp only_assignment(query, assignment_id) when is_integer(assignment_id) do
    where(query, [assignment: assignment], assignment.id == ^assignment_id)
  end

  # The first owner of every auth node, in one pass over the role assignments.
  defp first_owner_per_node_query do
    from(role in RoleAssignment,
      where: role.role == :owner,
      distinct: [role.node_id],
      order_by: [asc: role.node_id, asc: role.inserted_at, asc: role.principal_id],
      select: %{node_id: role.node_id, principal_id: role.principal_id}
    )
  end

  @doc """
  Project assignments with their client and project item, filtered by the
  Client activity filters (`:this_year`, `:published`).

  Bindings: `:client`, `:assignment`, `:item`, `:user`.
  """
  def client_assignment_query(filters, %Date{} = today, assignment_id \\ nil) do
    from(client in subquery(assignment_client_query(assignment_id)),
      as: :client,
      join: assignment in Assignment.Model,
      as: :assignment,
      on: assignment.id == client.assignment_id,
      join: item in Project.ItemModel,
      as: :item,
      on: item.assignment_id == assignment.id,
      join: user in Account.User,
      as: :user,
      on: user.id == client.client_id
    )
    |> filter_client_assignments(filters, today)
  end

  defp filter_client_assignments(query, filters, today) do
    Enum.reduce(filters, query, &filter_client_assignments_by(&2, &1, today))
  end

  defp filter_client_assignments_by(query, :published, _today) do
    where(query, [assignment: assignment], assignment.status != :concept)
  end

  defp filter_client_assignments_by(query, :this_year, %Date{year: year}) do
    start_of_year = NaiveDateTime.new!(year, 1, 1, 0, 0, 0)
    start_of_next_year = NaiveDateTime.new!(year + 1, 1, 1, 0, 0, 0)

    where(
      query,
      [assignment: assignment],
      assignment.inserted_at >= ^start_of_year and assignment.inserted_at < ^start_of_next_year
    )
  end
end
