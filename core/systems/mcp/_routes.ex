defmodule Systems.Mcp.Routes do
  @moduledoc """
  Routes for MCP server management and token operations.

  These routes provide HTTP access to MCP functionality for:
  - Token management
  - Actor creation
  - Usage statistics
  - Token validation
  """

  defmacro routes do
    quote do
      scope "/api/mcp", Systems.MCP do
        pipe_through([:api])

        # Token management routes
        post("/actors", Controller, :create_actor)
        get("/tokens", Controller, :list_tokens)
        post("/tokens/rotate", Controller, :rotate_token)
        delete("/tokens", Controller, :revoke_token)
        post("/tokens/validate", Controller, :validate_token)

        # Statistics and maintenance
        get("/stats", Controller, :get_stats)
        post("/cleanup", Controller, :cleanup_tokens)
      end
    end
  end
end
