defmodule GreenLight.Access do
  @moduledoc """
  Helper functions to check if a given user can access / invoke something.
  """
  alias GreenLight.PermissionMap

  def can?(permission_map, roles, permission) do
    permission_map |> PermissionMap.allowed?(permission, roles)
  end
end
