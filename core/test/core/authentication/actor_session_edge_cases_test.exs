defmodule Core.Authentication.ActorSessionEdgeCasesTest do
  use Core.DataCase
  import Plug.Test
  import Plug.Conn

  alias Core.Authentication.{Actor, ActorSession, ActorToken}
  alias Core.Repo

  # Factory functions for test data
  defp create_actor(attrs \\ %{}) do
    %Actor{
      type: :agent,
      name: "Test Actor #{System.unique_integer([:positive])}",
      description: "Test actor for edge cases",
      active: true
    }
    |> struct!(attrs)
    |> Actor.change()
    |> Actor.validate()
    |> Repo.insert!()
  end

  describe "ActorSession.create_api_token/3" do
    test "creates API token with all valid parameters" do
      actor = create_actor()
      created_by = create_actor(%{name: "Creator Actor"})

      assert {:ok, token, token_record} =
               ActorSession.create_api_token(actor, "Test Token", created_by)

      assert is_binary(token)
      assert String.length(token) > 20, "Token should be substantial length"
      assert token_record.actor_id == actor.id
      assert token_record.name == "Test Token"
      assert token_record.context == "api"
      assert token_record.created_by_actor_id == created_by.id
    end

    test "creates API token without created_by_actor" do
      actor = create_actor()

      assert {:ok, token, token_record} = ActorSession.create_api_token(actor, "No Creator Token")

      assert is_binary(token)
      assert token_record.actor_id == actor.id
      assert token_record.created_by_actor_id == nil
    end

    test "handles very long token names" do
      actor = create_actor()
      long_name = String.duplicate("a", 300)

      result = ActorSession.create_api_token(actor, long_name)

      case result do
        {:ok, _token, _record} ->
          # If successful, database accepts long names
          assert true

        {:error, changeset} ->
          # Should be validation error, not crash
          assert changeset.errors[:name] != nil, "Should have name length validation"
      end
    end

    test "handles empty and nil token names" do
      actor = create_actor()

      test_cases = [
        {nil, "nil name"},
        {"", "empty name"},
        {"   ", "whitespace name"}
      ]

      Enum.each(test_cases, fn {name, description} ->
        result = ActorSession.create_api_token(actor, name)

        case result do
          {:ok, _token, _record} ->
            # Some names might be valid
            assert true

          {:error, changeset} ->
            assert changeset.errors[:name] != nil, "Should validate name for #{description}"
        end
      end)
    end

    test "handles invalid actor (nil)" do
      assert_raise FunctionClauseError, fn ->
        ActorSession.create_api_token(nil, "Invalid Actor Token")
      end
    end

    test "handles inactive actor" do
      inactive_actor = create_actor(%{active: false})

      # Should still create token for inactive actor
      # (business logic might validate this elsewhere)
      assert {:ok, _token, token_record} =
               ActorSession.create_api_token(inactive_actor, "Inactive Token")

      assert token_record.actor_id == inactive_actor.id
    end

    test "handles concurrent token creation for same actor" do
      actor = create_actor()

      tasks =
        Enum.map(1..5, fn i ->
          Task.async(fn ->
            ActorSession.create_api_token(actor, "Concurrent Token #{i}")
          end)
        end)

      results = Enum.map(tasks, &Task.await(&1, 5000))

      successful_results =
        Enum.filter(results, fn
          {:ok, _token, _record} -> true
          _ -> false
        end)

      assert length(successful_results) == 5, "All concurrent token creations should succeed"

      # All tokens should be unique
      tokens = Enum.map(successful_results, fn {:ok, token, _record} -> token end)
      unique_tokens = Enum.uniq(tokens)
      assert length(tokens) == length(unique_tokens), "All tokens should be unique"
    end
  end

  describe "ActorSession.create_session_token/2" do
    test "creates session token with expiration" do
      actor = create_actor()

      assert {:ok, token, token_record} = ActorSession.create_session_token(actor)

      assert is_binary(token)
      assert token_record.actor_id == actor.id
      assert token_record.context == "session"
      assert token_record.expires_at != nil, "Session tokens should have expiration"
      assert token_record.name == "session"
    end

    test "creates session token with created_by_actor" do
      actor = create_actor()
      created_by = create_actor(%{name: "Session Creator"})

      assert {:ok, _token, token_record} = ActorSession.create_session_token(actor, created_by)
      assert token_record.created_by_actor_id == created_by.id
    end

    test "handles invalid actor types for session tokens" do
      assert_raise FunctionClauseError, fn ->
        ActorSession.create_session_token("not an actor")
      end
    end
  end

  describe "ActorSession.verify_api_token/1" do
    test "successfully verifies valid API token" do
      actor = create_actor()
      {:ok, token, _record} = ActorSession.create_api_token(actor, "Verify Test")

      assert {:ok, verified_actor} = ActorSession.verify_api_token(token)
      assert verified_actor.id == actor.id
      assert verified_actor.name == actor.name
    end

    test "rejects invalid token format" do
      assert {:error, :invalid_token} = ActorSession.verify_api_token("invalid_token")
    end

    test "rejects empty and nil tokens" do
      assert {:error, :invalid_token} = ActorSession.verify_api_token("")
      assert {:error, :invalid_token} = ActorSession.verify_api_token(nil)
    end

    test "rejects expired tokens" do
      actor = create_actor()
      {:ok, token, token_record} = ActorSession.create_api_token(actor, "Expiry Test")

      # Manually expire the token
      expired_time = NaiveDateTime.add(NaiveDateTime.utc_now(), -1, :day) |> NaiveDateTime.truncate(:second)

      token_record
      |> Ecto.Changeset.change(%{expires_at: expired_time})
      |> Repo.update!()

      assert {:error, :invalid_token} = ActorSession.verify_api_token(token)
    end

    test "rejects tokens for inactive actors" do
      actor = create_actor()
      {:ok, token, _record} = ActorSession.create_api_token(actor, "Inactive Test")

      # Deactivate the actor
      actor
      |> Actor.change(%{active: false})
      |> Repo.update!()

      assert {:error, :invalid_token} = ActorSession.verify_api_token(token)
    end

    test "updates last_used_at timestamp on successful verification" do
      actor = create_actor()
      {:ok, token, token_record} = ActorSession.create_api_token(actor, "Usage Test")

      # Verify initial state
      assert token_record.last_used_at == nil

      # Verify token
      assert {:ok, _verified_actor} = ActorSession.verify_api_token(token)

      # Check that last_used_at was updated
      updated_record = Repo.get!(ActorToken, token_record.id)
      assert updated_record.last_used_at != nil
      assert NaiveDateTime.compare(updated_record.last_used_at, NaiveDateTime.utc_now()) == :lt
    end

    test "handles malformed base64 tokens" do
      malformed_tokens = [
        "not_base64!@#",
        # Valid base64 but wrong content
        "SGVsbG8gV29ybGQ",
        "====invalid===",
        # Very long string
        String.duplicate("a", 1000)
      ]

      Enum.each(malformed_tokens, fn bad_token ->
        assert {:error, :invalid_token} = ActorSession.verify_api_token(bad_token)
      end)
    end
  end

  describe "ActorSession.verify_session_token/1" do
    test "successfully verifies valid session token" do
      actor = create_actor()
      {:ok, token, _record} = ActorSession.create_session_token(actor)

      assert {:ok, verified_actor} = ActorSession.verify_session_token(token)
      assert verified_actor.id == actor.id
    end

    test "rejects expired session tokens" do
      actor = create_actor()
      {:ok, token, token_record} = ActorSession.create_session_token(actor)

      # Manually expire the session token
      expired_time = 
        NaiveDateTime.utc_now()
        |> NaiveDateTime.truncate(:second)
        |> NaiveDateTime.add(-1, :day) 

      token_record
      |> Ecto.Changeset.change(%{expires_at: expired_time})
      |> Repo.update!()

      assert {:error, :invalid_token} = ActorSession.verify_session_token(token)
    end

    test "handles non-binary token input" do
      assert {:error, :invalid_token} = ActorSession.verify_session_token(123)
    end
  end

  describe "ActorSession token revocation functions" do
    test "revoke_api_token successfully revokes token" do
      actor = create_actor()
      {:ok, token, _record} = ActorSession.create_api_token(actor, "Revoke Test")

      # Verify token works
      assert {:ok, _actor} = ActorSession.verify_api_token(token)

      # Revoke token
      assert {:ok, _deleted_record} = ActorSession.revoke_api_token(token)

      # Verify token no longer works
      assert {:error, :invalid_token} = ActorSession.verify_api_token(token)
    end

    test "revoke_session_token successfully revokes session token" do
      actor = create_actor()
      {:ok, token, _record} = ActorSession.create_session_token(actor)

      assert {:ok, _actor} = ActorSession.verify_session_token(token)
      assert {:ok, _deleted_record} = ActorSession.revoke_session_token(token)
      assert {:error, :invalid_token} = ActorSession.verify_session_token(token)
    end

    test "revoke_all_api_tokens removes all API tokens for actor" do
      actor = create_actor()

      # Create multiple API tokens
      {:ok, token1, _} = ActorSession.create_api_token(actor, "Token 1")
      {:ok, token2, _} = ActorSession.create_api_token(actor, "Token 2")
      {:ok, token3, _} = ActorSession.create_api_token(actor, "Token 3")

      # Verify all work
      assert {:ok, _} = ActorSession.verify_api_token(token1)
      assert {:ok, _} = ActorSession.verify_api_token(token2)
      assert {:ok, _} = ActorSession.verify_api_token(token3)

      # Revoke all
      {count, _} = ActorSession.revoke_all_api_tokens(actor)
      assert count == 3, "Should revoke 3 API tokens"

      # Verify none work
      assert {:error, :invalid_token} = ActorSession.verify_api_token(token1)
      assert {:error, :invalid_token} = ActorSession.verify_api_token(token2)
      assert {:error, :invalid_token} = ActorSession.verify_api_token(token3)
    end

    test "revoke_all_session_tokens removes all session tokens for actor" do
      actor = create_actor()

      # Create multiple session tokens
      {:ok, token1, _} = ActorSession.create_session_token(actor)
      {:ok, token2, _} = ActorSession.create_session_token(actor)

      assert {:ok, _} = ActorSession.verify_session_token(token1)
      assert {:ok, _} = ActorSession.verify_session_token(token2)

      {count, _} = ActorSession.revoke_all_session_tokens(actor)
      assert count == 2, "Should revoke 2 session tokens"

      assert {:error, :invalid_token} = ActorSession.verify_session_token(token1)
      assert {:error, :invalid_token} = ActorSession.verify_session_token(token2)
    end

    test "revocation functions handle non-existent tokens gracefully" do
      assert {:error, :token_not_found} = ActorSession.revoke_api_token("non_existent_token")
      assert {:error, :token_not_found} = ActorSession.revoke_session_token("non_existent_token")
    end
  end

  describe "ActorSession token listing functions" do
    test "list_api_tokens returns only API tokens for actor" do
      actor = create_actor()
      other_actor = create_actor(%{name: "Other Actor"})

      # Create mixed tokens
      {:ok, _api_token1, _} = ActorSession.create_api_token(actor, "API Token 1")
      {:ok, _api_token2, _} = ActorSession.create_api_token(actor, "API Token 2")
      {:ok, _session_token, _} = ActorSession.create_session_token(actor)
      {:ok, _other_api_token, _} = ActorSession.create_api_token(other_actor, "Other API")

      api_tokens = ActorSession.list_api_tokens(actor)

      assert length(api_tokens) == 2, "Should return only actor's API tokens"
      assert Enum.all?(api_tokens, &(&1.context == "api"))
      assert Enum.all?(api_tokens, &(&1.actor_id == actor.id))
    end

    test "list_session_tokens returns only session tokens for actor" do
      actor = create_actor()

      {:ok, _api_token, _} = ActorSession.create_api_token(actor, "API Token")
      {:ok, _session_token1, _} = ActorSession.create_session_token(actor)
      {:ok, _session_token2, _} = ActorSession.create_session_token(actor)

      session_tokens = ActorSession.list_session_tokens(actor)

      assert length(session_tokens) == 2, "Should return only session tokens"
      assert Enum.all?(session_tokens, &(&1.context == "session"))
      assert Enum.all?(session_tokens, &(&1.actor_id == actor.id))
    end

    test "list functions exclude expired tokens" do
      actor = create_actor()

      # Create tokens
      {:ok, _active_token, _} = ActorSession.create_api_token(actor, "Active Token")

      {:ok, _expired_token, expired_record} =
        ActorSession.create_api_token(actor, "Expired Token")

      # Expire one token
      expired_time = 
        NaiveDateTime.utc_now()
        |> NaiveDateTime.truncate(:second)
        |> NaiveDateTime.add(-1, :day) 
      
      expired_record
      |> Ecto.Changeset.change(%{expires_at: expired_time})
      |> Repo.update!()

      api_tokens = ActorSession.list_api_tokens(actor)

      assert length(api_tokens) == 1, "Should exclude expired tokens"
      assert hd(api_tokens).name == "Active Token"
    end

    test "list functions handle actors with no tokens" do
      actor = create_actor()

      assert ActorSession.list_api_tokens(actor) == []
      assert ActorSession.list_session_tokens(actor) == []
    end
  end

  describe "ActorSession Plug functions" do
    test "authenticate_api_token plug succeeds with valid Bearer token" do
      actor = create_actor()
      {:ok, token, _} = ActorSession.create_api_token(actor, "Plug Test")

      conn =
        conn(:get, "/test")
        |> put_req_header("authorization", "Bearer #{token}")
        |> ActorSession.authenticate_api_token([])

      assert conn.assigns.current_actor.id == actor.id
      refute conn.halted
    end

    test "authenticate_api_token plug fails with invalid token" do
      conn =
        conn(:get, "/test")
        |> put_req_header("authorization", "Bearer invalid_token")
        |> ActorSession.authenticate_api_token([])

      assert conn.status == 401
      assert conn.halted
      assert get_resp_header(conn, "content-type") |> hd() =~ "application/json"
    end

    test "authenticate_api_token plug fails with missing Authorization header" do
      conn =
        conn(:get, "/test")
        |> ActorSession.authenticate_api_token([])

      assert conn.status == 401
      assert conn.halted
    end

    test "authenticate_api_token plug fails with malformed Authorization header" do
      malformed_headers = [
        # Wrong auth type
        "Basic username:password",
        # Missing token
        "Bearer",
        # Empty token
        "Bearer  ",
        # Wrong format
        "InvalidFormat token"
      ]

      Enum.each(malformed_headers, fn header ->
        conn =
          conn(:get, "/test")
          |> put_req_header("authorization", header)
          |> ActorSession.authenticate_api_token([])

        assert conn.status == 401
        assert conn.halted
      end)
    end

    test "maybe_authenticate_api_token plug assigns nil for missing token" do
      conn =
        conn(:get, "/test")
        |> ActorSession.maybe_authenticate_api_token([])

      assert conn.assigns.current_actor == nil
      refute conn.halted
    end

    test "maybe_authenticate_api_token plug assigns nil for invalid token" do
      conn =
        conn(:get, "/test")
        |> put_req_header("authorization", "Bearer invalid_token")
        |> ActorSession.maybe_authenticate_api_token([])

      assert conn.assigns.current_actor == nil
      refute conn.halted
    end

    test "maybe_authenticate_api_token plug assigns actor for valid token" do
      actor = create_actor()
      {:ok, token, _} = ActorSession.create_api_token(actor, "Maybe Test")

      conn =
        conn(:get, "/test")
        |> put_req_header("authorization", "Bearer #{token}")
        |> ActorSession.maybe_authenticate_api_token([])

      assert conn.assigns.current_actor.id == actor.id
      refute conn.halted
    end

    test "authenticate_session_token plug works with session cookies" do
      actor = create_actor()
      {:ok, token, _} = ActorSession.create_session_token(actor)

      conn =
        conn(:get, "/test")
        |> put_req_cookie("actor_session_token", token)
        |> ActorSession.authenticate_session_token([])

      assert conn.assigns.current_actor.id == actor.id
      refute conn.halted
    end

    test "authenticate_session_token plug works with Bearer header" do
      actor = create_actor()
      {:ok, token, _} = ActorSession.create_session_token(actor)

      conn =
        conn(:get, "/test")
        |> put_req_header("authorization", "Bearer #{token}")
        |> ActorSession.authenticate_session_token([])

      assert conn.assigns.current_actor.id == actor.id
      refute conn.halted
    end

    test "authenticate_session_token plug fails with no authentication" do
      conn =
        conn(:get, "/test")
        |> ActorSession.authenticate_session_token([])

      assert conn.status == 401
      assert conn.halted
    end

    test "require_authenticated_actor plug succeeds with authenticated actor" do
      actor = create_actor()

      conn =
        conn(:get, "/test")
        |> assign(:current_actor, actor)
        |> ActorSession.require_authenticated_actor([])

      refute conn.halted
    end

    test "require_authenticated_actor plug fails without authenticated actor" do
      conn =
        conn(:get, "/test")
        |> ActorSession.require_authenticated_actor([])

      assert conn.status == 401
      assert conn.halted
    end

    test "require_authenticated_actor plug fails with nil current_actor" do
      conn =
        conn(:get, "/test")
        |> assign(:current_actor, nil)
        |> ActorSession.require_authenticated_actor([])

      assert conn.status == 401
      assert conn.halted
    end
  end

  describe "edge cases with token contexts" do
    test "API and session tokens are isolated by context" do
      actor = create_actor()

      # Create tokens in both contexts with same actor
      {:ok, api_token, _} = ActorSession.create_api_token(actor, "API Context")
      {:ok, session_token, _} = ActorSession.create_session_token(actor)

      # API token should not work for session verification
      assert {:error, :invalid_token} = ActorSession.verify_session_token(api_token)

      # Session token should not work for API verification
      assert {:error, :invalid_token} = ActorSession.verify_api_token(session_token)
    end

    test "revoking API tokens doesn't affect session tokens" do
      actor = create_actor()

      {:ok, api_token, _} = ActorSession.create_api_token(actor, "API")
      {:ok, session_token, _} = ActorSession.create_session_token(actor)

      # Revoke all API tokens
      ActorSession.revoke_all_api_tokens(actor)

      # API token should be invalid
      assert {:error, :invalid_token} = ActorSession.verify_api_token(api_token)

      # Session token should still work
      assert {:ok, _} = ActorSession.verify_session_token(session_token)
    end
  end
end
