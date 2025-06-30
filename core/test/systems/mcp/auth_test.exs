defmodule Systems.MCP.AuthTest do
  use Core.DataCase

  alias Systems.MCP.Auth
  alias Systems.MCP.Factories
  alias Core.Authentication.Actor

  describe "authenticate_actor_from_params/1" do
    test "successfully authenticates with valid auth_token" do
      {actor, token, _token_record} = Factories.create_actor_with_token()

      params = %{"auth_token" => token}

      assert {:ok, authenticated_actor} = Auth.authenticate_actor_from_params(params)
      assert authenticated_actor.id == actor.id
      assert authenticated_actor.name == actor.name
    end

    test "returns error when auth_token is missing" do
      params = %{}

      assert {:error, :missing_auth_token} = Auth.authenticate_actor_from_params(params)
    end

    test "returns error when auth_token is nil" do
      params = %{"auth_token" => nil}

      assert {:error, :missing_auth_token} = Auth.authenticate_actor_from_params(params)
    end

    test "returns error when auth_token is invalid" do
      params = %{"auth_token" => "invalid_token"}

      assert {:error, :invalid_token} = Auth.authenticate_actor_from_params(params)
    end

    test "returns error when auth_token is expired" do
      {_actor, token, _token_record} = Factories.create_expired_token_actor()

      params = %{"auth_token" => token}

      assert {:error, :invalid_token} = Auth.authenticate_actor_from_params(params)
    end
  end

  describe "ensure_mcp_authorized/1" do
    test "allows active agent actors" do
      actor = Factories.build_actor(%{type: :agent, active: true})

      assert :ok = Auth.ensure_mcp_authorized(actor)
    end

    test "allows active system actors" do
      actor = Factories.build_actor(%{type: :system, active: true})

      assert :ok = Auth.ensure_mcp_authorized(actor)
    end

    test "rejects inactive actors" do
      actor = Factories.build_actor(%{active: false})

      assert {:error, :actor_inactive} = Auth.ensure_mcp_authorized(actor)
    end

    test "rejects actors with invalid types" do
      # Create an actor struct with an invalid type (bypassing Ecto validation)
      invalid_actor = %Actor{type: :invalid, active: true}

      assert {:error, :actor_not_authorized} = Auth.ensure_mcp_authorized(invalid_actor)
    end
  end

  describe "get_current_actor/1" do
    test "extracts actor from frame with valid actor" do
      actor = Factories.build_actor()
      frame = %{actor: actor}

      assert {:ok, extracted_actor} = Auth.get_current_actor(frame)
      assert extracted_actor == actor
    end

    test "returns error when frame has no actor" do
      frame = %{}

      assert {:error, :no_authenticated_actor} = Auth.get_current_actor(frame)
    end

    test "returns error when frame has invalid actor" do
      frame = %{actor: "not_an_actor"}

      assert {:error, :no_authenticated_actor} = Auth.get_current_actor(frame)
    end
  end

  describe "mcp_auth_error/1" do
    test "formats missing_auth_token error" do
      error = Auth.mcp_auth_error(:missing_auth_token)

      assert error.error.code == "AUTHENTICATION_FAILED"
      assert error.error.message == "Authentication token required"
      assert error.error.data.reason == :missing_auth_token
    end

    test "formats invalid_token error" do
      error = Auth.mcp_auth_error(:invalid_token)

      assert error.error.code == "AUTHENTICATION_FAILED"
      assert error.error.message == "Invalid or expired authentication token"
      assert error.error.data.reason == :invalid_token
    end

    test "formats actor_inactive error" do
      error = Auth.mcp_auth_error(:actor_inactive)

      assert error.error.code == "AUTHENTICATION_FAILED"
      assert error.error.message == "Actor account is inactive"
      assert error.error.data.reason == :actor_inactive
    end

    test "formats actor_not_authorized error" do
      error = Auth.mcp_auth_error(:actor_not_authorized)

      assert error.error.code == "AUTHENTICATION_FAILED"
      assert error.error.message == "Actor not authorized for MCP operations"
      assert error.error.data.reason == :actor_not_authorized
    end

    test "formats no_authenticated_actor error" do
      error = Auth.mcp_auth_error(:no_authenticated_actor)

      assert error.error.code == "AUTHENTICATION_FAILED"
      assert error.error.message == "No authenticated actor in request context"
      assert error.error.data.reason == :no_authenticated_actor
    end

    test "formats unknown error" do
      error = Auth.mcp_auth_error(:unknown_error)

      assert error.error.code == "AUTHENTICATION_FAILED"
      assert error.error.message == "Authentication failed"
      assert error.error.data.reason == :unknown_error
    end
  end

  describe "with_auth/2" do
    test "executes function with valid authenticated actor" do
      actor = Factories.build_actor(%{active: true, type: :agent})
      frame = %{actor: actor}

      tool_function = fn received_actor ->
        assert received_actor == actor
        {:ok, "success"}
      end

      assert {:ok, "success"} = Auth.with_auth(frame, tool_function)
    end

    test "returns auth error when actor is inactive" do
      actor = Factories.build_actor(%{active: false})
      frame = %{actor: actor}

      tool_function = fn _actor -> {:ok, "should not execute"} end

      assert {:error, error} = Auth.with_auth(frame, tool_function)
      assert error.error.code == "AUTHENTICATION_FAILED"
      assert error.error.data.reason == :actor_inactive
    end

    test "returns auth error when actor is not authorized" do
      invalid_actor = %Actor{type: :invalid, active: true}
      frame = %{actor: invalid_actor}

      tool_function = fn _actor -> {:ok, "should not execute"} end

      assert {:error, error} = Auth.with_auth(frame, tool_function)
      assert error.error.code == "AUTHENTICATION_FAILED"
      assert error.error.data.reason == :actor_not_authorized
    end

    test "returns auth error when no actor in frame" do
      frame = %{}

      tool_function = fn _actor -> {:ok, "should not execute"} end

      assert {:error, error} = Auth.with_auth(frame, tool_function)
      assert error.error.code == "AUTHENTICATION_FAILED"
      assert error.error.data.reason == :no_authenticated_actor
    end

    test "propagates tool function errors" do
      actor = Factories.build_actor(%{active: true, type: :agent})
      frame = %{actor: actor}

      tool_function = fn _actor -> {:error, "tool error"} end

      assert {:error, "tool error"} = Auth.with_auth(frame, tool_function)
    end
  end
end
