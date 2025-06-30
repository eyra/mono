defmodule Systems.MCP.ControllerTest do
  use CoreWeb.ConnCase

  alias Systems.MCP.{TokenManager, Factories}
  alias Core.Authentication.ActorSession

  describe "create_actor/2" do
    test "creates agent actor with token successfully", %{conn: conn} do
      params = %{
        "name" => "Test Agent",
        "description" => "Test agent description",
        "token_name" => "Test Token"
      }

      conn = post(conn, "/api/mcp/actors", params)

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert json["data"]["actor"]["name"] == "Test Agent"
      assert json["data"]["actor"]["type"] == "agent"
      assert json["data"]["actor"]["active"] == true
      assert is_binary(json["data"]["token"])
      assert String.contains?(json["data"]["instructions"]["usage"], json["data"]["token"])
    end

    test "creates system actor when type specified", %{conn: conn} do
      params = %{
        "name" => "System Actor",
        "type" => "system"
      }

      conn = post(conn, "/api/mcp/actors", params)

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert json["data"]["actor"]["type"] == "system"
    end

    test "returns error for invalid actor data", %{conn: conn} do
      params = %{
        # Empty name should fail validation
        "name" => ""
      }

      conn = post(conn, "/api/mcp/actors", params)

      assert json = json_response(conn, 400)
      assert json["success"] == false
      assert json["error"] == "Failed to create actor"
      assert Map.has_key?(json, "details")
    end

    test "returns error for duplicate actor name", %{conn: conn} do
      name = "Duplicate Actor"

      # Create first actor
      TokenManager.create_mcp_actor(name)

      # Try to create another with same name
      params = %{"name" => name}
      conn = post(conn, "/api/mcp/actors", params)

      assert json = json_response(conn, 400)
      assert json["success"] == false
    end
  end

  describe "list_tokens/2" do
    test "returns empty list when no tokens exist", %{conn: conn} do
      # Clear existing tokens
      Core.Repo.delete_all(Core.Authentication.ActorToken)

      conn = get(conn, "/api/mcp/tokens")

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert json["data"]["tokens"] == []
      assert json["data"]["statistics"]["total_active_tokens"] == 0
    end

    test "returns tokens with statistics", %{conn: conn} do
      Factories.create_actor_with_token()

      conn = get(conn, "/api/mcp/tokens")

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert is_list(json["data"]["tokens"])
      assert length(json["data"]["tokens"]) >= 1
      assert is_map(json["data"]["statistics"])
      assert json["data"]["statistics"]["total_active_tokens"] >= 1
    end
  end

  describe "rotate_token/2" do
    test "rotates token successfully with revocation", %{conn: conn} do
      {_actor, old_token, _token_record} = Factories.create_actor_with_token()

      params = %{
        "old_token" => old_token,
        "new_token_name" => "Rotated Token",
        "revoke_old" => true
      }

      conn = post(conn, "/api/mcp/tokens/rotate", params)

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert is_binary(json["data"]["new_token"])
      assert json["data"]["new_token"] != old_token
      assert json["data"]["old_token_revoked"] == true
      assert String.contains?(json["data"]["instructions"], json["data"]["new_token"])

      # Verify old token is invalid
      assert {:error, :invalid_token} = ActorSession.verify_api_token(old_token)

      # Verify new token is valid
      assert {:ok, _actor} = ActorSession.verify_api_token(json["data"]["new_token"])
    end

    test "rotates token without revoking old one", %{conn: conn} do
      {_actor, old_token, _token_record} = Factories.create_actor_with_token()

      params = %{
        "old_token" => old_token,
        "revoke_old" => false
      }

      conn = post(conn, "/api/mcp/tokens/rotate", params)

      assert json = json_response(conn, 200)
      assert json["data"]["old_token_revoked"] == false

      # Both tokens should be valid
      assert {:ok, _actor} = ActorSession.verify_api_token(old_token)
      assert {:ok, _actor} = ActorSession.verify_api_token(json["data"]["new_token"])
    end

    test "returns error for invalid old token", %{conn: conn} do
      params = %{
        "old_token" => "invalid_token"
      }

      conn = post(conn, "/api/mcp/tokens/rotate", params)

      assert json = json_response(conn, 400)
      assert json["success"] == false
      assert json["error"] == "Token rotation failed"
    end
  end

  describe "revoke_token/2" do
    test "revokes token successfully", %{conn: conn} do
      {_actor, token, _token_record} = Factories.create_actor_with_token()

      params = %{"token" => token}

      conn = delete(conn, "/api/mcp/tokens", params)

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert json["message"] == "Token revoked successfully"

      # Verify token is now invalid
      assert {:error, :invalid_token} = ActorSession.verify_api_token(token)
    end

    test "returns error for invalid token", %{conn: conn} do
      params = %{"token" => "invalid_token"}

      conn = delete(conn, "/api/mcp/tokens", params)

      assert json = json_response(conn, 400)
      assert json["success"] == false
      assert json["error"] == "Failed to revoke token"
    end
  end

  describe "validate_token/2" do
    test "validates valid token successfully", %{conn: conn} do
      {actor, token, _token_record} = Factories.create_actor_with_token()

      params = %{"token" => token}

      conn = post(conn, "/api/mcp/tokens/validate", params)

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert json["valid"] == true
      assert json["data"]["actor"]["id"] == actor.id
      assert json["data"]["actor"]["name"] == actor.name
      assert json["data"]["actor"]["type"] == Atom.to_string(actor.type)
      assert json["data"]["actor"]["active"] == actor.active
    end

    test "returns invalid for bad token", %{conn: conn} do
      params = %{"token" => "invalid_token"}

      conn = post(conn, "/api/mcp/tokens/validate", params)

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert json["valid"] == false
      assert json["message"] == "Invalid or expired token"
    end

    test "returns invalid for expired token", %{conn: conn} do
      {_actor, token, _token_record} = Factories.create_expired_token_actor()

      params = %{"token" => token}

      conn = post(conn, "/api/mcp/tokens/validate", params)

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert json["valid"] == false
    end
  end

  describe "get_stats/2" do
    test "returns token usage statistics", %{conn: conn} do
      conn = get(conn, "/api/mcp/stats")

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert is_map(json["data"])
      assert is_integer(json["data"]["total_active_tokens"])
      assert is_integer(json["data"]["recently_used_tokens"])
      assert Map.has_key?(json["data"], "last_updated")
    end
  end

  describe "cleanup_tokens/2" do
    test "performs cleanup and returns count", %{conn: conn} do
      conn = post(conn, "/api/mcp/cleanup")

      assert json = json_response(conn, 200)
      assert json["success"] == true
      assert json["message"] == "Cleanup completed"
      assert is_integer(json["tokens_removed"])
      assert json["tokens_removed"] >= 0
    end
  end

  # Test edge cases and error handling

  describe "error handling" do
    test "handles missing parameters gracefully", %{conn: conn} do
      # Test create_actor without required name
      conn = post(conn, "/api/mcp/actors", %{})
      assert json_response(conn, 400)["success"] == false
    end

    test "handles malformed JSON gracefully", %{conn: conn} do
      # This would typically be handled by Phoenix's JSON parsing
      # but we can test parameter validation
      conn = post(conn, "/api/mcp/actors", %{"name" => nil})
      assert json_response(conn, 400)["success"] == false
    end
  end
end
