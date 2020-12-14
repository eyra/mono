defmodule GreenLight do
  @moduledoc """
  Defines an authorization module.

  When used, the authorization module expects a list of possible roles.

  An authorization module defines all the permissions with their role mappings.
  Permissions are defined by using the grant_* helpers
  (`GreenLight.Permissions.grant_access/2`,
  `GreenLight.Permissions.grant_actions/2`).


  """
  alias GreenLight.Config

  @doc false
  defmacro __using__(config) do
    quote do
      @behaviour GreenLight

      unquote(__MODULE__).__register_permission_map()
      unquote(__MODULE__).__register_schema_and_roles(unquote(config))
      unquote(__MODULE__).__register_authorization_functions(unquote(config))
      unquote(__MODULE__).__register_query_functions(unquote(config))
    end
  end

  defmacro __register_permission_map do
    quote do
      @before_compile GreenLight.Permissions
      import GreenLight.Permissions, only: [grant_access: 2, grant_actions: 2]

      GreenLight.Permissions.setup_permission_map(__MODULE__)
    end
  end

  defmacro __register_schema_and_roles(config) do
    quote do
      @green_light_role_assignment_schema unquote(Config.role_assignment_schema!(config))
      @green_light_roles MapSet.new(unquote(Config.roles!(config)))

      def role_assignment_schema do
        @green_light_role_assignment_schema
      end

      def possible_roles do
        @green_light_roles
      end
    end
  end

  defmacro __register_authorization_functions(config) do
    repo = Config.repo!(config)
    schema = Config.role_assignment_schema!(config)

    quote do
      def allowed?(roles, permission) do
        permission_map() |> GreenLight.PermissionMap.allowed?(permission, roles)
      end

      def list_roles(%GreenLight.Principal{} = principal, entities) do
        unquote(repo)
        |> GreenLight.Ecto.Query.list_roles(unquote(schema), principal, entities)
        |> Enum.concat(principal.roles)
      end

      def assign_role!(%GreenLight.Principal{} = principal, entity, role) do
        unquote(repo)
        |> GreenLight.Ecto.Query.assign_role!(unquote(schema), principal, entity, role)
      end

      @doc """
      Assign a role by piping the result of an Ecto insert operation directly into
      this function.
      """
      def assign_role({:ok, entity} = result, principal, role) do
        assign_role!(principal, entity, role)
        result
      end

      def assign_role({:error, _} = result, _principal, _role), do: result

      def can?(%GreenLight.Principal{} = principal, entity_or_entities, module, action) do
        roles = list_roles(principal, entity_or_entities)

        GreenLight.Access.can?(
          permission_map(),
          roles,
          GreenLight.Permissions.action_permission(module, action)
        )
      end
    end
  end

  defmacro __register_query_functions(config) do
    schema = Config.role_assignment_schema!(config)

    quote do
      def query_entity_ids(opts \\ []) do
        GreenLight.Ecto.Query.query_entity_ids(unquote(schema), opts)
      end
    end
  end

  ## User callbacks
  @callback principal(conn :: Plug.Conn.t()) :: GreenLight.Principal.t()
end
