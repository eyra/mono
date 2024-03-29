defmodule Frameworks.GreenLight.Plug do
  @moduledoc """
  This Plug validates the permissions before the request is allowed to proceed.
  """
  import Plug.Conn
  alias Frameworks.GreenLight
  require Logger

  def init(auth_module), do: auth_module

  def call(
        %Plug.Conn{
          private: %{phoenix_controller: phoenix_controller, phoenix_action: phoenix_action}
        } = conn,
        auth_module
      ) do
    # This code mandates a permission assignment for the current user and
    # the controller being invoked. It will make the authorization check
    # before the controller code is executed.

    principal = auth_module.principal(conn)

    {entities, conn} = phoenix_controller.load_entities(conn)
    entity_roles = auth_module.list_roles(principal, entities)

    conn = Plug.Conn.put_private(conn, :auth_principal_roles, principal.roles)

    case validate_permissions(conn, entities, entity_roles, auth_module) do
      {:error, {principal_roles, required_permission}} ->
        Logger.debug(
          "Principal with roles: #{principal_roles |> Enum.join(", ")} is not allowed to: `#{required_permission}`."
        )

        conn
        |> resp(401, "The current principal is not allowed access.")
        |> halt()

      {:ok, conn} ->
        conn
        |> ensure_authorization(
          GreenLight.Permissions.action_permission(phoenix_controller, phoenix_action),
          auth_module
        )
    end
  end

  defp validate_permissions(conn, entities, entity_roles, auth_module) do
    Enum.zip(entities, entity_roles)
    |> Enum.reduce_while({:ok, conn}, fn {entity, entity_roles}, {_, conn} ->
      roles = entity_roles |> MapSet.union(conn.private.auth_principal_roles)
      validate_permission(conn, entity, roles, auth_module)
    end)
  end

  defp validate_permission(conn, entity, roles, auth_module) do
    if is_nil(entity) do
      {:halt, {:ok, Plug.Conn.put_private(conn, :auth_principal_roles, roles)}}
    else
      permission =
        entity.__struct__
        |> GreenLight.Permissions.access_permission()

      if auth_module.allowed?(roles, permission) do
        {:cont, {:ok, Plug.Conn.put_private(conn, :auth_principal_roles, roles)}}
      else
        {:halt, {:error, {roles, permission}}}
      end
    end
  end

  defp ensure_authorization(
         %{private: %{auth_principal_roles: roles}} = conn,
         permission,
         auth_module
       ) do
    # Validate the entity with the current use against the permission map
    if auth_module.allowed?(roles, permission) do
      conn
    else
      conn
      |> resp(401, "The current principal does not have permission: #{permission}")
      |> halt()
    end
  end

  defmacro __using__(auth_module) do
    quote do
      @behaviour unquote(__MODULE__)
      @green_light_auth_module unquote(auth_module)
      plug(unquote(__MODULE__), @green_light_auth_module)

      def load_entities(%Plug.Conn{} = conn), do: {[], conn}
      defoverridable load_entities: 1
    end
  end

  ## User callbacks
  @callback load_entities(conn :: Plug.Conn.t()) :: {list(any()), Plug.Conn.t()}
end
