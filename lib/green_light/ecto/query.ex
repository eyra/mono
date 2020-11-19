defmodule GreenLight.Ecto.Query do
  @moduledoc """
  Query functions around role assignments.
  """

  import Ecto.Query

  defp get_db_entity(entity) do
    {Atom.to_string(entity.__struct__), entity.id}
  end

  defp role_query(role_assignment_schema, principal, entity) do
    {entity_type, entity_id} = get_db_entity(entity)

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

  def list_roles(repo, role_assignment_schema, %GreenLight.Principal{} = principal, entity) do
    if is_nil(principal.id) do
      MapSet.new()
    else
      role_query(role_assignment_schema, principal, entity)
      |> repo.all()
      |> MapSet.new()
    end
  end

  def assign_role!(
        repo,
        role_assignment_schema,
        %GreenLight.Principal{id: principal_id},
        entity,
        role
      ) do
    {entity_type, entity_id} = get_db_entity(entity)

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
end
