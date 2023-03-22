defmodule Frameworks.GreenLight.Public do
  @moduledoc """
  Defines an authorization module.

  When used, the authorization module expects a list of possible roles.

  An authorization module defines all the permissions with their role mappings.
  Permissions are defined by using the grant_* helpers
  (`Frameworks.GreenLight.Permissions.grant_access/2`,
  `Frameworks.GreenLight.Permissions.grant_actions/2`).


  """

  @doc false
  defmacro __using__(config) do
    quote do
      unquote(__MODULE__).__register_permission_map()
      unquote(__MODULE__).__register_schema_and_roles(unquote(config))
      unquote(__MODULE__).__register_helpers()
      unquote(__MODULE__).__register_authorization_check_functions()
      unquote(__MODULE__).__register_authorization_management_functions(unquote(config))
      unquote(__MODULE__).__register_query_functions(unquote(config))
    end
  end

  defmacro __register_permission_map do
    quote do
      @before_compile Frameworks.GreenLight.Permissions
      import Frameworks.GreenLight.Permissions, only: [grant_access: 2, grant_actions: 2]

      Frameworks.GreenLight.Permissions.setup_permission_map(__MODULE__)
    end
  end

  defmacro __register_schema_and_roles(config) do
    quote do
      @green_light_role_assignment_schema unquote(
                                            Frameworks.GreenLight.Config.role_assignment_schema!(
                                              config
                                            )
                                          )
      @green_light_roles MapSet.new(unquote(Frameworks.GreenLight.Config.roles!(config)))

      def role_assignment_schema do
        @green_light_role_assignment_schema
      end

      def possible_roles do
        @green_light_roles
      end
    end
  end

  defmacro __register_helpers do
    quote do
      def allowed?(roles, permission) do
        permission_map() |> Frameworks.GreenLight.PermissionMap.allowed?(permission, roles)
      end
    end
  end

  defmacro __register_authorization_check_functions do
    quote do
      def can?(principal, entity_or_entities, module, action) do
        roles = list_roles(principal, entity_or_entities)

        Frameworks.GreenLight.Access.can?(
          permission_map(),
          roles,
          Frameworks.GreenLight.Permissions.action_permission(module, action)
        )
      end

      @spec can?(any, Frameworks.GreenLight.PermissionMap.permission()) :: boolean
      def can?(principal, permission) when is_binary(permission) do
        roles = Frameworks.GreenLight.Principal.roles(principal)
        Frameworks.GreenLight.PermissionMap.allowed?(permission_map(), permission, roles)
      end
    end
  end

  defmacro __register_authorization_management_functions(config) do
    repo = Frameworks.GreenLight.Config.repo!(config)
    schema = Frameworks.GreenLight.Config.role_assignment_schema!(config)

    quote do
      def list_roles(principal, entities) do
        Frameworks.GreenLight.Ecto.Query.list_roles(
          unquote(repo),
          unquote(schema),
          principal,
          entities
        )
      end

      def build_role_assignment(principal, entity, role) do
        unquote(schema)
        |> struct(%{
          principal_id: Frameworks.GreenLight.Principal.id(principal),
          node_id: Frameworks.GreenLight.AuthorizationNode.id(entity),
          role: role
        })
      end

      @doc """
      Assign a role by piping the result of an Ecto insert operation directly into
      this function.
      """
      def assign_role({:ok, entity} = result, principal, role) do
        :ok = assign_role(principal, entity, role)
        result
      end

      def assign_role({:error, _} = result, _principal, _role), do: result

      def assign_role(principal, entity, role) when is_atom(role) do
        Frameworks.GreenLight.Ecto.Query.assign_role(
          unquote(repo),
          unquote(schema),
          principal,
          entity,
          role
        )
      end

      def remove_role!(principal, entity, role) do
        unquote(repo)
        |> Frameworks.GreenLight.Ecto.Query.remove_role!(
          unquote(schema),
          principal,
          entity,
          role
        )
      end

      def list_principals(entity) do
        unquote(repo)
        |> Frameworks.GreenLight.Ecto.Query.list_principals(unquote(schema), entity)
      end
    end
  end

  defmacro __register_query_functions(config) do
    schema = Frameworks.GreenLight.Config.role_assignment_schema!(config)

    quote do
      def query_node_ids(opts \\ []) do
        Frameworks.GreenLight.Ecto.Query.query_node_ids(unquote(schema), opts)
      end

      def query_principal_ids(opts \\ []) do
        Frameworks.GreenLight.Ecto.Query.query_principal_ids(unquote(schema), opts)
      end

      def query_role_assignment(principal, entity, role) do
        unquote(schema)
        |> Frameworks.GreenLight.Ecto.Query.query_role_assignments(
          principal: principal,
          entity: entity,
          role: role
        )
      end
    end
  end
end
