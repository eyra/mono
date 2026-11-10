defmodule Frameworks.GreenLight.Permissions do
  @moduledoc """
  The permissions module provides several functions that create permission
  strings and `GreenLight.PermissionMap`s.
  """
  alias Frameworks.GreenLight.{PermissionMap, Permissions}

  defp atom_to_permission_name(val) do
    val
    |> Atom.to_string()
    |> String.replace_prefix("Elixir.", "")
    |> String.split(".")
    |> Enum.map_join("/", &Macro.underscore/1)
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
    Module.put_attribute(module, :permission_map, PermissionMap.new())
  end

  defp get_permission_map_from_module(module) do
    Module.get_attribute(module, :permission_map)
  end

  def grant(module, permission, roles) do
    permission_map =
      get_permission_map_from_module(module) |> PermissionMap.grant(permission, roles)

    Module.put_attribute(module, :permission_map, permission_map)
  end

  def grant(module, permission_map) do
    permission_map =
      get_permission_map_from_module(module)
      |> PermissionMap.merge(permission_map)

    Module.put_attribute(
      module,
      :permission_map,
      permission_map
    )
  end

  defmacro grant_access(module, roles) do
    quote bind_quoted: [module: module, roles: roles] do
      permission = Permissions.access_permission(module)
      Permissions.grant(__MODULE__, permission, roles)
    end
  end

  defmacro grant_actions(module, action_to_roles_map) do
    quote bind_quoted: [module: module, action_to_roles_map: action_to_roles_map] do
      permission_map = Permissions.actions_permission_map(module, action_to_roles_map)

      Permissions.grant(__MODULE__, permission_map)
    end
  end

  @doc """
  The permission map of grants given as data: `{module, roles}` as for
  `grant_access/2`, `{module, %{action => roles}}` as for `grant_actions/2`.
  Raises when a permission is in `permission_map` already or granted twice: a
  grant never widens another one silently.
  """
  def grants_permission_map(permission_map, grants) do
    Enum.reduce(grants, permission_map, fn
      {module, %{} = action_to_roles}, acc ->
        Enum.reduce(action_to_roles, acc, fn {action, roles}, acc ->
          grant_once(acc, action_permission(module, action), roles)
        end)

      {module, roles}, acc when is_list(roles) ->
        grant_once(acc, access_permission(module), roles)

      other, _acc ->
        raise ArgumentError, "not a grant: #{inspect(other)}"
    end)
  end

  defp grant_once(permission_map, permission, roles) do
    if PermissionMap.granted?(permission_map, permission) do
      raise ArgumentError, "#{permission} is granted more than once"
    end

    PermissionMap.grant(permission_map, permission, roles)
  end

  @doc false
  # The compiled permission map of `module` merged with the grants that `{m, f, a}`
  # returns, built on the first call and cached until the node restarts.
  def runtime_permission_map(module, permission_map, {m, f, a}) do
    key = {__MODULE__, module}

    case :persistent_term.get(key, nil) do
      nil ->
        merged = grants_permission_map(permission_map, apply(m, f, a))
        :persistent_term.put(key, merged)
        merged

      merged ->
        merged
    end
  end

  defmacro __before_compile__(env) do
    case Module.get_attribute(env.module, :green_light_grants) do
      nil ->
        quote do
          def permission_map, do: @permission_map |> PermissionMap.new_t()
        end

      grants ->
        quote do
          def permission_map do
            Permissions.runtime_permission_map(
              __MODULE__,
              @permission_map,
              unquote(grants)
            )
            |> PermissionMap.new_t()
          end
        end
    end
  end
end
