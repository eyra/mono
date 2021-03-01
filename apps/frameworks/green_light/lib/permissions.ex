defmodule GreenLight.Permissions do
  @moduledoc """
  The permissions module provides several functions that create permission
  strings and `GreenLight.PermissionMap`s.
  """
  alias GreenLight.PermissionMap

  defp atom_to_permission_name(val) do
    val
    |> Atom.to_string()
    |> String.replace_prefix("Elixir.", "")
    |> String.split(".")
    |> Enum.map(&Macro.underscore/1)
    |> Enum.join("/")
  end

  def access_permission(module) do
    "access/#{module |> atom_to_permission_name()}"
  end

  def action_permission(module, action) do
    action_string = action |> Atom.to_string()
    "invoke/#{module |> atom_to_permission_name()}@#{action_string}"
  end

  def actions_permission_map(module, action_to_roles_map) do
    action_to_roles_map
    |> Enum.reduce(PermissionMap.new(), fn {action, roles}, permission_map ->
      PermissionMap.grant(
        permission_map,
        action_permission(module, action),
        roles
      )
    end)
  end

  def setup_permission_map(module) do
    Module.register_attribute(module, :permission_map, [])
    Module.put_attribute(module, :permission_map, GreenLight.PermissionMap.new())
  end

  def grant(module, permission, roles) do
    permission_map =
      Module.get_attribute(module, :permission_map) |> PermissionMap.grant(permission, roles)

    Module.put_attribute(module, :permission_map, permission_map)
  end

  def grant(module, %{} = permission_map) do
    permission_map =
      Module.get_attribute(module, :permission_map)
      |> PermissionMap.merge(permission_map)

    Module.put_attribute(
      module,
      :permission_map,
      permission_map
    )
  end

  defmacro grant_access(module, roles) do
    quote bind_quoted: [module: module, roles: roles] do
      permission = GreenLight.Permissions.access_permission(module)
      GreenLight.Permissions.grant(__MODULE__, permission, roles)
    end
  end

  defmacro grant_actions(module, action_to_roles_map) do
    quote bind_quoted: [module: module, action_to_roles_map: action_to_roles_map] do
      permission_map = GreenLight.Permissions.actions_permission_map(module, action_to_roles_map)

      GreenLight.Permissions.grant(__MODULE__, permission_map)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def permission_map, do: @permission_map
    end
  end
end
