defmodule Systems.MCP.Auth do
  @moduledoc """
  Authentication helpers for MCP server operations.

  Provides functions for extracting actor authentication from MCP requests
  and ensuring proper authorization for MCP tool execution.
  """

  alias Core.Authentication.{Actor, ActorSession}

  @doc """
  Authenticates an actor from MCP initialization parameters.

  Expects auth_token to be provided in the initialize parameters.
  """
  def authenticate_actor_from_params(%{"auth_token" => token}) when is_binary(token) do
    ActorSession.verify_api_token(token)
  end

  def authenticate_actor_from_params(_params) do
    {:error, :missing_auth_token}
  end

  @doc """
  Ensures the authenticated actor is active and authorized for MCP operations.
  """
  def ensure_mcp_authorized(%Actor{active: true, type: type}) when type in [:system, :agent] do
    :ok
  end

  def ensure_mcp_authorized(%Actor{active: false}) do
    {:error, :actor_inactive}
  end

  def ensure_mcp_authorized(_) do
    {:error, :actor_not_authorized}
  end

  @doc """
  Extracts actor from MCP frame context.

  Assumes the actor was set during server initialization.
  """
  def get_current_actor(%{actor: %Actor{} = actor}), do: {:ok, actor}
  def get_current_actor(_frame), do: {:error, :no_authenticated_actor}

  @doc """
  Creates a standardized MCP authentication error response.
  """
  def mcp_auth_error(reason) when is_atom(reason) do
    message =
      case reason do
        :missing_auth_token -> "Authentication token required"
        :invalid_token -> "Invalid or expired authentication token"
        :actor_inactive -> "Actor account is inactive"
        :actor_not_authorized -> "Actor not authorized for MCP operations"
        :no_authenticated_actor -> "No authenticated actor in request context"
        _ -> "Authentication failed"
      end

    %{
      error: %{
        code: "AUTHENTICATION_FAILED",
        message: message,
        data: %{reason: reason}
      }
    }
  end

  @doc """
  Wraps MCP tool execution with authentication checks.

  Ensures the actor is authenticated and authorized before executing the tool function.
  """
  def with_auth(frame, tool_function) when is_function(tool_function, 1) do
    case get_current_actor(frame) do
      {:ok, actor} ->
        case ensure_mcp_authorized(actor) do
          :ok -> tool_function.(actor)
          {:error, reason} -> {:error, mcp_auth_error(reason)}
        end

      {:error, reason} ->
        {:error, mcp_auth_error(reason)}
    end
  end
end
