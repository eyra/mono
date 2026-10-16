defmodule Frameworks.GreenLight.PermissionMap do
  @moduledoc """
  The permission map holds a mapping of permissions to roles. The permission map
  is intended to be an implementation detail of the authorization framework.
  Convenience functions to build it are provided in other modules.
  """

  @type role :: atom
  @type permission :: binary
  @type role_set :: MapSet.t(role)
  @type role_list :: [role]
  @type role_enum :: role_set | role_list
  @opaque t :: %{permission => role_list}

  @spec new() :: t
  def new() do
    Map.new()
  end

  @spec new(%{permission => role_enum}) :: t
  def new(%{} = mapping) do
    Enum.reduce(mapping, new(), fn {permission, roles}, permission_map ->
      grant(permission_map, permission, roles)
    end)
  end

  @doc """
  This constructor is here to appease Dialyzer when a PermissionMap is used as a module attribute.
  """
  @spec new_t(any()) :: t
  def new_t(permission_map) do
    permission_map
  end

  @doc """
  Return a `MapSet` of roles for a given permission. This always returns a
  `MapSet` (might be empty).
  """
  @spec roles(t, permission) :: role_set
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
  @spec grant(t, permission, role | role_list) :: t
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
  @spec allowed?(t, permission, role | role_list) :: boolean
  def allowed?(permission_map, permission, principal_roles) when is_list(principal_roles) do
    allowed?(permission_map, permission, MapSet.new(principal_roles))
  end

  @spec allowed?(t, binary, role_set) :: boolean
  def allowed?(permission_map, permission, principal_roles) do
    not (permission_map |> roles(permission) |> MapSet.disjoint?(principal_roles))
  end

  @doc """
  Merge two permission maps. The result of the merge is a permission map for
  which a permission that is available in either (or both) maps has the combined
  roles of both permission maps.
  """
  @spec merge(t, t) :: t
  def merge(a, b) when a == %{}, do: b
  def merge(a, b) when b == %{}, do: a

  def merge(a, b) do
    Enum.reduce(a, b, fn {permission, roles}, permission_map ->
      grant(permission_map, permission, roles |> MapSet.to_list())
    end)
  end
end
