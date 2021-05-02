defmodule GreenLight.Ecto.Query do
  @moduledoc """
  Query functions around role assignments.
  """

  import Ecto.Query
  alias GreenLight.AuthorizationNode
  alias GreenLight.Principal

  defp role_query(role_assignment_schema, principal, entity) do
    from(ra in role_assignment_schema,
      select: ra.role,
      where:
        ra.principal_id == ^Principal.id(principal) and
          ra.node_id == ^AuthorizationNode.id(entity)
    )
  end

  def list_roles(repo, role_assignment_schema, principal, entities)
      when is_list(entities) do
    Enum.map(entities, &list_roles(repo, role_assignment_schema, principal, &1))
  end

  def list_roles(
        repo,
        role_assignment_schema,
        principal,
        entity
      ) do
    if is_nil(Principal.id(principal)) do
      MapSet.new()
    else
      role_query(role_assignment_schema, principal, entity)
      |> repo.all()
      |> MapSet.new()
    end
  end

  def assign_role(
        repo,
        role_assignment_schema,
        principal,
        entity,
        role
      ) do
    role_assignment_schema
    |> struct(%{
      principal_id: Principal.id(principal),
      node_id: AuthorizationNode.id(entity),
      role: role
    })
    |> repo.insert()
    |> case do
      {:ok, _} -> :ok
      {:error, _} -> :error
    end
  end

  def remove_role!(
        repo,
        role_assignment_schema,
        principal,
        entity,
        role
      ) do
    query_role_assignments(
      role_assignment_schema,
      principal: principal,
      entity: entity,
      role: role
    )
    |> repo.delete_all()
  end

  def list_principals(repo, role_assignment_schema, entity) do
    query =
      query_role_assignments(role_assignment_schema,
        entity: entity
      )

    from(ra in query, select: {ra.principal_id, ra.role}, order_by: [ra.principal_id, ra.role])
    |> repo.all
    |> Enum.group_by(fn {principal_id, _} -> principal_id end, fn {_, role} -> role end)
    |> Enum.map(fn {principal_id, roles} ->
      %{id: principal_id, roles: MapSet.new(roles)}
    end)
  end

  def query_role_assignments(role_assignment_schema, opts \\ []) do
    filters =
      opts
      |> Enum.reduce([], fn {option, value}, filters ->
        filter =
          case option do
            :role -> {:role, value}
            :entity -> {:node_id, AuthorizationNode.id(value)}
            :principal -> {:principal_id, Principal.id(value)}
          end

        [filter | filters]
      end)

    Ecto.Query.from(ra in role_assignment_schema, where: ^filters)
  end

  def query_node_ids(role_assignment_schema, opts \\ []) do
    query = query_role_assignments(role_assignment_schema, opts)
    Ecto.Query.from(ra in query, select: ra.node_id)
  end
end
