defmodule GreenLight.Access do
  alias GreenLight.PermissionMap

  def can?(permission_map, roles, permission) do
    permission_map |> PermissionMap.allowed?(permission, roles)
  end
end
