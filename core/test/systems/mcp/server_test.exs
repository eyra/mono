defmodule Systems.MCP.ServerTest do
  use Core.DataCase

  alias Systems.MCP.{Server, Factories}
  alias Core.Authentication.Actor

  describe "initialize/1" do
    test "successfully initializes with valid authenticated actor" do
      {actor, token, _token_record} = Factories.create_actor_with_token()

      params = %{"auth_token" => token}

      assert {:ok, result} = Server.initialize(params)

      assert result.actor.id == actor.id

      expected_tools = [
        "create_concepts",
        "create_predicates", 
        "create_concept",
        "create_predicate",
        "create_annotation",
        "query_knowledge",
        "get_feedback_loop",
        "validate_pattern",
        "list_patterns"
      ]
      
      actual_tools = Map.keys(result.capabilities.tools) |> Enum.sort()
      assert Enum.sort(expected_tools) == actual_tools

      assert result.server_info.name == "Knowledge System MCP Server"
      assert result.server_info.version == "1.0.0"
    end

    test "successfully initializes with system actor" do
      {actor, token, _token_record} = Factories.create_system_actor_with_token()

      params = %{"auth_token" => token}

      assert {:ok, result} = Server.initialize(params)
      assert result.actor.id == actor.id
      assert result.actor.type == :system
    end

    test "returns error when auth_token is missing" do
      params = %{}

      assert {:error, error} = Server.initialize(params)
      assert error.error.code == "AUTHENTICATION_FAILED"
      assert error.error.data.reason == :missing_auth_token
    end

    test "returns error when auth_token is invalid" do
      params = %{"auth_token" => "invalid_token"}

      assert {:error, error} = Server.initialize(params)
      assert error.error.code == "AUTHENTICATION_FAILED"
      assert error.error.data.reason == :invalid_token
    end

    test "returns error when actor is inactive" do
      # Create an active actor with token first, then deactivate
      {actor, token, _token_record} = Factories.create_actor_with_token()

      # Deactivate the actor
      actor
      |> Core.Authentication.Actor.change(%{active: false})
      |> Core.Repo.update!()

      params = %{"auth_token" => token}

      assert {:error, error} = Server.initialize(params)
      assert error.error.code == "AUTHENTICATION_FAILED"
      # The actor verification in ActorToken will return :invalid_token for inactive actors
      assert error.error.data.reason == :invalid_token
    end
  end

  describe "call_tool/3" do
    setup do
      {actor, _token, _token_record} = Factories.create_actor_with_token()
      frame = %{actor: actor}

      %{actor: actor, frame: frame}
    end

    test "tool calls pass authentication layer", %{frame: frame} do
      # Test that authentication works for tool calls
      # External system integration is tested separately

      # Test with unknown tool first to verify the call path works
      assert {:error, error} = Server.call_tool("unknown_tool", %{}, frame)
      assert error.error.code == "TOOL_NOT_FOUND"

      # This confirms that:
      # 1. Authentication passed (no auth error)
      # 2. Tool dispatch logic worked (got tool not found error)
      # 3. The call_tool function properly processes requests
    end

    test "returns error for unknown tool", %{frame: frame} do
      assert {:error, error} = Server.call_tool("unknown_tool", %{}, frame)

      assert error.error.code == "TOOL_NOT_FOUND"
      assert error.error.message == "Unknown tool: unknown_tool"
    end

    test "returns auth error when frame has no actor" do
      frame = %{}

      assert {:error, error} = Server.call_tool("create_concepts", %{}, frame)
      assert error.error.code == "AUTHENTICATION_FAILED"
      assert error.error.data.reason == :no_authenticated_actor
    end

    test "returns auth error when actor is inactive", %{actor: actor} do
      inactive_actor = %{actor | active: false}
      frame = %{actor: inactive_actor}

      assert {:error, error} = Server.call_tool("create_concepts", %{}, frame)
      assert error.error.code == "AUTHENTICATION_FAILED"
      assert error.error.data.reason == :actor_inactive
    end

    test "returns auth error when actor is not authorized" do
      invalid_actor = %Actor{type: :invalid, active: true}
      frame = %{actor: invalid_actor}

      assert {:error, error} = Server.call_tool("create_concepts", %{}, frame)
      assert error.error.code == "AUTHENTICATION_FAILED"
      assert error.error.data.reason == :actor_not_authorized
    end
  end
end
