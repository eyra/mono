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
  grant never widens another one silently. A grant that does widen one says so
  with a third element, `{module, roles, widen: true}`, and adds its roles to
  that permission; it raises when it widens no permission.
  """
  def grants_permission_map(permission_map, grants) do
    Enum.reduce(grants, permission_map, fn
      {module, roles, widen: true}, acc ->
        grant(acc, module, roles, &widen/3)

      {module, roles}, acc ->
        grant(acc, module, roles, &grant_once/3)

      other, _acc ->
        raise ArgumentError, "not a grant: #{inspect(other)}"
    end)
  end

  defp grant(permission_map, module, %{} = action_to_roles, grant_fun) do
    Enum.reduce(action_to_roles, permission_map, fn {action, roles}, acc ->
      grant_fun.(acc, action_permission(module, action), roles)
    end)
  end

  defp grant(permission_map, module, roles, grant_fun) when is_list(roles),
    do: grant_fun.(permission_map, access_permission(module), roles)

  defp grant(_permission_map, module, roles, _grant_fun),
    do: raise(ArgumentError, "not a grant: #{inspect({module, roles})}")

  defp grant_once(permission_map, permission, roles) do
    if PermissionMap.granted?(permission_map, permission) do
      raise ArgumentError,
            "#{permission} is granted more than once; a grant that widens another one " <>
              "says `widen: true`"
    end

    PermissionMap.grant(permission_map, permission, roles)
  end

  defp widen(permission_map, permission, roles) do
    unless PermissionMap.granted?(permission_map, permission) do
      raise ArgumentError, "#{permission} is not granted before, so `widen: true` widens nothing"
    end

    PermissionMap.grant(permission_map, permission, roles)
  end

  @doc false
  # The compiled permission map of `module` merged with the grants that `{m, f, a}`
  # returns, built on the first call and cached until the node restarts. The
  # cache is rebuilt when the compiled map or the grants change (a recompile in
  # dev, a test that puts other grants).
  def runtime_permission_map(module, permission_map, {m, f, a}) do
    key = {__MODULE__, module}
    grants = apply(m, f, a)

    case :persistent_term.get(key, nil) do
      {^permission_map, ^grants, merged} ->
        merged

      _ ->
        merged = grants_permission_map(permission_map, grants)
        :persistent_term.put(key, {permission_map, grants, merged})
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
          @doc false
          # The grants compiled into the module, without the runtime ones.
          def compiled_permission_map, do: @permission_map

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
