defmodule Frameworks.GreenLight.Access do
  @moduledoc """
  Helper functions to check if a given user can access / invoke something.
  """
  alias Frameworks.GreenLight.PermissionMap

  def can?(permission_map, roles, permission) do
    PermissionMap.allowed?(permission_map, permission, roles)
  end
end
