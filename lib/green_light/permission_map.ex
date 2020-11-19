defmodule GreenLight.PermissionMap do
  @moduledoc """
  The permission map holds a mapping of permissions to roles. The permission map
  is intended to be an implementation detail of the authorization framework.
  Convenience functions to build it are provided in other modules.
  """

  def new() do
    Map.new()
  end

  def new(%{} = mapping) do
    Enum.reduce(mapping, new(), fn {permission, roles}, permission_map ->
      grant(permission_map, permission, roles)
    end)
  end

  @doc """
  Return a `MapSet` of roles for a given permission. This always returns a
  `MapSet` (might be empty).
  """
  def roles(permission_map, permission) do
    Map.get(permission_map, permission, MapSet.new())
  end

  def list_permission_assignments(permission_map) do
    permission_map
    |> Enum.sort()
    |> Enum.map(fn {permission, roles} ->
      {permission, roles |> Enum.sort()}
    end)
  end

  @doc """
  Add a mapping for the given role and permission if does not already exist.
  """
  def grant(permission_map, permission, role) when is_atom(role) do
    Map.update(permission_map, permission, MapSet.new([role]), &MapSet.put(&1, role))
  end

  def grant(permission_map, permission, roles) when is_list(roles) do
    Enum.reduce(roles, permission_map, &grant(&2, permission, &1))
  end

  @doc """
  Returns wheter or not a the given set of roles should be allowed for the given
  permission.
  """
  def allowed?(permission_map, permission, %MapSet{} = principal_roles) do
    not (roles(permission_map, permission)
         |> MapSet.disjoint?(principal_roles))
  end

  def allowed?(permission_map, permission, principal_roles) do
    allowed?(permission_map, permission, MapSet.new(principal_roles))
  end

  @doc """
  Merge two permission maps. The result of the merge is a permission map for
  which a permission that is available in either (or both) maps has the combined
  roles of both permission maps.
  """
  def merge(a, b) when a == %{}, do: b
  def merge(a, b) when b == %{}, do: a

  def merge(a, b) do
    Enum.reduce(a, b, fn {permission, roles}, permission_map ->
      grant(permission_map, permission, roles |> MapSet.to_list())
    end)
  end
end
