defmodule Systems.Admin.Queries do
  require Ecto.Query
  import Ecto.Query, warn: false

  alias Core.Authorization.RoleAssignment
  alias Systems.Account
  alias Systems.Assignment
  alias Systems.Fund
  alias Systems.Project

  @doc """
  Maps every project assignment to its client: one row `%{assignment_id, client_id}`.

  This is the only place that decides who the client of an assignment is, so the
  Client activity tab can move from users to organisations by changing this query.

  The data model has no assignment creator, so the client is approximated by:
  1. the first owner of the assignment's fund (the fund is created with the
     creating user as its only owner), falling back to
  2. the first remaining owner of the assignment's project.
  """
  def assignment_client_query do
    from(assignment in Assignment.Model,
      as: :assignment,
      join: item in Project.ItemModel,
      on: item.assignment_id == assignment.id,
      join: project in Project.Model,
      as: :project,
      on: project.root_id == item.node_id,
      left_join: fund in Fund.Model,
      as: :fund,
      on: fund.id == assignment.fund_id,
      left_lateral_join: fund_owner in subquery(first_fund_owner_query()),
      on: true,
      left_lateral_join: project_owner in subquery(first_project_owner_query()),
      on: true,
      where: not is_nil(coalesce(fund_owner.principal_id, project_owner.principal_id)),
      select: %{
        assignment_id: assignment.id,
        client_id: coalesce(fund_owner.principal_id, project_owner.principal_id)
      }
    )
  end

  defp first_fund_owner_query do
    from(role in RoleAssignment,
      where: role.node_id == parent_as(:fund).auth_node_id and role.role == :owner,
      order_by: [asc: role.inserted_at, asc: role.principal_id],
      limit: 1,
      select: %{principal_id: role.principal_id}
    )
  end

  defp first_project_owner_query do
    from(role in RoleAssignment,
      where: role.node_id == parent_as(:project).auth_node_id and role.role == :owner,
      order_by: [asc: role.inserted_at, asc: role.principal_id],
      limit: 1,
      select: %{principal_id: role.principal_id}
    )
  end

  @doc """
  Project assignments with their client and project item, filtered by the
  Client activity filters (`:this_year`, `:published`).

  Bindings: `:client`, `:assignment`, `:item`, `:user`.
  """
  def client_assignment_query(filters, %Date{} = today) do
    from(client in subquery(assignment_client_query()),
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
