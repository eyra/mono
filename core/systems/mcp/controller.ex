defmodule Systems.MCP.Controller do
  @moduledoc """
  Phoenix controller for MCP server management and token operations.

  Provides HTTP endpoints for managing MCP actors and tokens.
  Note: These endpoints should be protected by admin authentication in production.
  """

  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

  alias Systems.MCP.TokenManager
  alias Core.Authentication.ActorSession

  @doc """
  Creates a new MCP actor with token.

  POST /api/mcp/actors
  {
    "name": "My AI Agent",
    "description": "Description of the agent", 
    "token_name": "Custom token name",
    "type": "agent"
  }
  """
  def create_actor(conn, params) do
    name = params["name"]
    description = params["description"]
    token_name = params["token_name"]
    type = String.to_existing_atom(params["type"] || "agent")

    case TokenManager.create_mcp_actor_with_token(name, description, token_name, type) do
      {:ok, result} ->
        json(conn, %{
          success: true,
          data: %{
            actor: %{
              id: result.actor.id,
              name: result.actor.name,
              description: result.actor.description,
              type: result.actor.type,
              active: result.actor.active
            },
            token: result.token,
            instructions: result.instructions
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: "Failed to create actor",
          details: format_changeset_errors(changeset)
        })
    end
  end

  @doc """
  Lists all MCP tokens with usage information.

  GET /api/mcp/tokens
  """
  def list_tokens(conn, _params) do
    tokens = TokenManager.list_mcp_tokens()
    stats = TokenManager.get_token_usage_stats()

    json(conn, %{
      success: true,
      data: %{
        tokens: tokens,
        statistics: stats
      }
    })
  end

  @doc """
  Rotates an existing token.

  POST /api/mcp/tokens/rotate
  {
    "old_token": "current_token_here",
    "new_token_name": "New token name",
    "revoke_old": true
  }
  """
  def rotate_token(conn, params) do
    old_token = params["old_token"]
    new_token_name = params["new_token_name"]
    # Default to true
    revoke_old = params["revoke_old"] != false

    case TokenManager.rotate_token(old_token, new_token_name, revoke_old) do
      {:ok, result} ->
        json(conn, %{
          success: true,
          data: %{
            new_token: result.new_token,
            old_token_revoked: result.old_token_revoked,
            actor_name: result.actor.name,
            instructions: "Use new token in Authorization header: 'Bearer #{result.new_token}'"
          }
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: "Token rotation failed",
          reason: reason
        })
    end
  end

  @doc """
  Revokes a specific token.

  DELETE /api/mcp/tokens
  {
    "token": "token_to_revoke"
  }
  """
  def revoke_token(conn, %{"token" => token}) do
    case ActorSession.revoke_api_token(token) do
      {:ok, _} ->
        json(conn, %{
          success: true,
          message: "Token revoked successfully"
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: "Failed to revoke token",
          reason: reason
        })
    end
  end

  @doc """
  Validates a token and returns actor information.

  POST /api/mcp/tokens/validate
  {
    "token": "token_to_validate"
  }
  """
  def validate_token(conn, %{"token" => token}) do
    case ActorSession.verify_api_token(token) do
      {:ok, actor} ->
        json(conn, %{
          success: true,
          valid: true,
          data: %{
            actor: %{
              id: actor.id,
              name: actor.name,
              description: actor.description,
              type: actor.type,
              active: actor.active
            }
          }
        })

      {:error, _reason} ->
        json(conn, %{
          success: true,
          valid: false,
          message: "Invalid or expired token"
        })
    end
  end

  @doc """
  Gets token usage statistics.

  GET /api/mcp/stats
  """
  def get_stats(conn, _params) do
    stats = TokenManager.get_token_usage_stats()

    json(conn, %{
      success: true,
      data: stats
    })
  end

  @doc """
  Cleans up expired tokens.

  POST /api/mcp/cleanup
  """
  def cleanup_tokens(conn, _params) do
    case TokenManager.cleanup_expired_tokens() do
      {:ok, count} ->
        json(conn, %{
          success: true,
          message: "Cleanup completed",
          tokens_removed: count
        })

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          success: false,
          error: "Cleanup failed",
          reason: reason
        })
    end
  end

  # Private helper functions

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
