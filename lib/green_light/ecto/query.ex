defmodule GreenLight.Ecto.Query do
  @moduledoc """
  Query functions around role assignments.
  """

  import Ecto.Query

  defp role_query(role_assignment_schema, principal, entity_type, entity_id) do
    from(ra in role_assignment_schema,
      select: ra.role,
      where:
        ra.principal_id == ^principal.id and ra.entity_id == ^entity_id and
          ra.entity_type == ^entity_type
    )
  end

  def list_roles(repo, role_assignment_schema, %GreenLight.Principal{} = principal, entities)
      when is_list(entities) do
    Enum.map(entities, &list_roles(repo, role_assignment_schema, principal, &1))
  end

  def list_roles(_repo, _role_assignment_schema, %GreenLight.Principal{}, entity)
      when is_nil(entity),
      do: MapSet.new()

  def list_roles(
        repo,
        role_assignment_schema,
        %GreenLight.Principal{} = principal,
        {entity_type, entity_id}
      ) do
    if is_nil(principal.id) do
      MapSet.new()
    else
      role_query(role_assignment_schema, principal, entity_type, entity_id)
      |> repo.all()
      |> MapSet.new()
    end
  end

  def assign_role!(
        repo,
        role_assignment_schema,
        %GreenLight.Principal{id: principal_id},
        entity_type,
        entity_id,
        role
      ) do
    role_assignment_schema
    |> struct
    |> role_assignment_schema.changeset(%{
      principal_id: principal_id,
      entity_type: entity_type,
      entity_id: entity_id,
      role: role
    })
    |> repo.insert!()
  end

  def remove_role!(
        repo,
        role_assignment_schema,
        %GreenLight.Principal{} = principal,
        entity_type,
        entity_id,
        role
      ) do
    query_role_assignments(
      role_assignment_schema,
      principal: principal,
      entity_type: entity_type,
      entity_id: entity_id,
      role: role
    )
    |> repo.delete_all()
  end

  def list_principals(repo, role_assignment_schema, {entity_type, entity_id}) do
    query =
      query_role_assignments(role_assignment_schema,
        entity_type: entity_type,
        entity_id: entity_id
      )

    from(ra in query, select: {ra.principal_id, ra.role}, order_by: [ra.principal_id, ra.role])
    |> repo.all
    |> Enum.group_by(fn {principal_id, _} -> principal_id end, fn {_, role} -> role end)
    |> Enum.map(fn {principal_id, roles} ->
      %GreenLight.Principal{id: principal_id, roles: MapSet.new(roles)}
    end)
  end

  def query_role_assignments(role_assignment_schema, opts \\ []) do
    filters =
      opts
      |> Enum.reduce([], fn {option, value}, filters ->
        filter =
          case option do
            :role -> {:role, value}
            :entity_type -> {:entity_type, value |> to_string}
            :entity_id -> {:entity_id, value}
            :principal -> {:principal_id, value.id}
          end

        [filter | filters]
      end)

    Ecto.Query.from(ra in role_assignment_schema, where: ^filters)
  end

  def query_entity_ids(role_assignment_schema, opts \\ []) do
    query = query_role_assignments(role_assignment_schema, opts)
    Ecto.Query.from(ra in query, select: ra.entity_id)
  end
end
