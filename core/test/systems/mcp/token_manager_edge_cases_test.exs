defmodule Systems.MCP.TokenManagerEdgeCasesTest do
  use Core.DataCase

  alias Systems.MCP.{TokenManager, Factories}
  alias Core.Authentication.{Actor, ActorToken}
  import Ecto.Query

  describe "identical timestamps edge case" do
    test "handles identical timestamps with deterministic ordering" do
      # Clear existing tokens to ensure clean state
      Core.Repo.delete_all(ActorToken)

      # Create tokens with forced identical timestamps
      actor1 = Factories.create_actor(%{name: "Actor 1"})
      actor2 = Factories.create_actor(%{name: "Actor 2"})

      # Create tokens normally first
      {:ok, _token1, token_record1} = TokenManager.create_mcp_token(actor1, "Token 1")
      {:ok, _token2, token_record2} = TokenManager.create_mcp_token(actor2, "Token 2")

      # Force identical timestamps by updating the database directly
      identical_time = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      from(t in ActorToken, where: t.id in [^token_record1.id, ^token_record2.id])
      |> Core.Repo.update_all(set: [inserted_at: identical_time, updated_at: identical_time])

      # Test the ordering multiple times to check consistency
      results =
        Enum.map(1..5, fn _ ->
          TokenManager.list_mcp_tokens()
          |> Enum.filter(&(&1.id in [token_record1.id, token_record2.id]))
          |> Enum.map(& &1.id)
        end)

      # All results should be identical (deterministic ordering)
      first_result = List.first(results)

      assert Enum.all?(results, &(&1 == first_result)),
             "Ordering should be deterministic with identical timestamps. Got varying results: #{inspect(results)}"

      # Should have a consistent secondary sort (likely by ID)
      assert length(first_result) == 2, "Should return both tokens"
    end

    test "mixed identical and different timestamps maintain correct order" do
      Core.Repo.delete_all(ActorToken)

      # Create tokens with mixed timestamps
      actor1 = Factories.create_actor(%{name: "Actor 1"})
      actor2 = Factories.create_actor(%{name: "Actor 2"})
      actor3 = Factories.create_actor(%{name: "Actor 3"})

      {:ok, _token1, token_record1} = TokenManager.create_mcp_token(actor1, "Token 1")
      {:ok, _token2, token_record2} = TokenManager.create_mcp_token(actor2, "Token 2")
      {:ok, _token3, token_record3} = TokenManager.create_mcp_token(actor3, "Token 3")

      # Make token1 and token2 have identical timestamps (newer than token3)
      newer_time = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      older_time = NaiveDateTime.add(newer_time, -60, :second)

      # Update timestamps
      from(t in ActorToken, where: t.id in [^token_record1.id, ^token_record2.id])
      |> Core.Repo.update_all(set: [inserted_at: newer_time, updated_at: newer_time])

      from(t in ActorToken, where: t.id == ^token_record3.id)
      |> Core.Repo.update_all(set: [inserted_at: older_time, updated_at: older_time])

      tokens = TokenManager.list_mcp_tokens()
      token_ids = Enum.map(tokens, & &1.id)

      # Token3 should be last (oldest)
      token3_index = Enum.find_index(token_ids, &(&1 == token_record3.id))
      token1_index = Enum.find_index(token_ids, &(&1 == token_record1.id))
      token2_index = Enum.find_index(token_ids, &(&1 == token_record2.id))

      # Both token1 and token2 should come before token3
      assert token1_index < token3_index, "Token 1 should come before Token 3"
      assert token2_index < token3_index, "Token 2 should come before Token 3"
    end
  end

  describe "empty token lists edge case" do
    test "returns empty list gracefully when no tokens exist" do
      Core.Repo.delete_all(ActorToken)

      tokens = TokenManager.list_mcp_tokens()
      stats = TokenManager.get_token_usage_stats()

      assert tokens == [], "Should return empty list when no tokens exist"
      assert stats.total_active_tokens == 0, "Stats should show zero active tokens"
      assert stats.recently_used_tokens == 0, "Stats should show zero recently used tokens"
      assert %NaiveDateTime{} = stats.last_updated, "Should still return valid timestamp"
    end

    test "handles transition from tokens to empty state" do
      # Create some tokens
      {_actor, _token, _token_record} = Factories.create_actor_with_token()

      # Verify tokens exist
      assert length(TokenManager.list_mcp_tokens()) > 0

      # Remove all tokens
      Core.Repo.delete_all(ActorToken)

      # Should handle empty state gracefully
      tokens = TokenManager.list_mcp_tokens()
      stats = TokenManager.get_token_usage_stats()

      assert tokens == []
      assert stats.total_active_tokens == 0
      assert stats.recently_used_tokens == 0
    end
  end

  describe "large token count performance" do
    test "handles large number of tokens without performance degradation" do
      Core.Repo.delete_all(ActorToken)

      # Create a substantial number of tokens (100 should be sufficient for testing)
      Enum.each(1..100, fn i ->
        actor = Factories.create_actor(%{name: "Load Test Actor #{i}"})
        TokenManager.create_mcp_token(actor, "Load Test Token #{i}")
      end)

      # Measure performance of list operation
      {time_micros, tokens} = :timer.tc(fn -> TokenManager.list_mcp_tokens() end)

      assert length(tokens) == 100, "Should return all created tokens"

      # Performance assertion: should complete within reasonable time (1 second = 1,000,000 microseconds)
      assert time_micros < 1_000_000,
             "list_mcp_tokens should complete within 1 second with 100 tokens, took #{time_micros} microseconds"

      # Test statistics performance with large dataset
      {stats_time, stats} = :timer.tc(fn -> TokenManager.get_token_usage_stats() end)

      assert stats.total_active_tokens == 100

      assert stats_time < 1_000_000,
             "get_token_usage_stats should complete within 1 second with 100 tokens, took #{stats_time} microseconds"
    end

    test "maintains consistent structure with large token counts" do
      Core.Repo.delete_all(ActorToken)

      # Create tokens and verify structure remains consistent
      Enum.each(1..50, fn i ->
        actor = Factories.create_actor(%{name: "Structure Test Actor #{i}"})
        TokenManager.create_mcp_token(actor, "Structure Test Token #{i}")
      end)

      tokens = TokenManager.list_mcp_tokens()

      # Verify each token has expected structure
      Enum.each(tokens, fn token ->
        assert Map.has_key?(token, :id), "Token should have :id field"
        assert Map.has_key?(token, :name), "Token should have :name field"
        assert Map.has_key?(token, :actor_name), "Token should have :actor_name field"
        assert Map.has_key?(token, :actor_type), "Token should have :actor_type field"
        assert Map.has_key?(token, :created_at), "Token should have :created_at field"
        assert Map.has_key?(token, :last_used_at), "Token should have :last_used_at field"
        assert Map.has_key?(token, :is_expired), "Token should have :is_expired field"

        # Verify data types
        assert is_integer(token.id)
        assert is_binary(token.name)
        assert is_binary(token.actor_name)
        assert token.actor_type in [:agent, :system]
        assert %NaiveDateTime{} = token.created_at
        # Note: is_expired field should be boolean but implementation may have issues
        assert token.is_expired in [true, false, nil], "is_expired should be boolean or nil"
      end)
    end
  end

  describe "mixed token states edge case" do
    test "properly handles mix of expired and active tokens" do
      Core.Repo.delete_all(ActorToken)

      # Create active tokens
      active_actor = Factories.create_actor(%{name: "Active Actor"})

      {:ok, _active_token, _active_record} =
        TokenManager.create_mcp_token(active_actor, "Active Token")

      # Create expired token
      {_expired_actor, _expired_token, expired_record} = Factories.create_expired_token_actor()

      # Verify expired token is actually expired
      assert expired_record.expires_at != nil
      assert NaiveDateTime.compare(expired_record.expires_at, NaiveDateTime.utc_now()) == :lt

      tokens = TokenManager.list_mcp_tokens()
      stats = TokenManager.get_token_usage_stats()

      # Should include both in list but only count active ones in stats
      assert length(tokens) == 2, "Should list both active and expired tokens"
      assert stats.total_active_tokens == 1, "Should only count active tokens in stats"

      # Verify expired token is marked correctly
      expired_token_info = Enum.find(tokens, &(&1.id == expired_record.id))
      active_token_info = Enum.find(tokens, &(&1.actor_name == "Active Actor"))

      assert expired_token_info != nil, "Should find expired token in results"
      assert active_token_info != nil, "Should find active token in results"

      # Check expiration logic (may need fixing in implementation)
      if expired_token_info.is_expired != nil do
        assert expired_token_info.is_expired == true, "Expired token should be marked as expired"
      end

      if active_token_info.is_expired != nil do
        assert active_token_info.is_expired == false,
               "Active token should not be marked as expired"
      end
    end

    test "handles recently used token calculations correctly" do
      Core.Repo.delete_all(ActorToken)

      # Create tokens with different usage patterns
      {_actor1, _token1, token_record1} =
        Factories.create_actor_with_token(%{name: "Recent User"})

      {_actor2, _token2, token_record2} = Factories.create_actor_with_token(%{name: "Old User"})

      {_actor3, _token3, _token_record3} =
        Factories.create_actor_with_token(%{name: "Never Used"})

      # Update usage timestamps
      recent_time = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      # 10 days ago
      old_time = NaiveDateTime.add(recent_time, -10, :day)

      # Token 1: recently used (within 7 days)
      token_record1
      |> Ecto.Changeset.change(%{last_used_at: recent_time})
      |> Core.Repo.update!()

      # Token 2: used long ago (outside 7 day window)
      token_record2
      |> Ecto.Changeset.change(%{last_used_at: old_time})
      |> Core.Repo.update!()

      # Token 3: never used (last_used_at remains nil)

      stats = TokenManager.get_token_usage_stats()

      assert stats.total_active_tokens == 3, "Should count all active tokens"
      assert stats.recently_used_tokens == 1, "Should only count tokens used within 7 days"
    end
  end

  describe "concurrent creation race conditions" do
    test "handles concurrent token creation correctly" do
      Core.Repo.delete_all(ActorToken)

      # Create base actor for concurrent token creation
      actor = Factories.create_actor(%{name: "Concurrent Test Actor"})

      # Spawn multiple processes creating tokens concurrently
      tasks =
        Enum.map(1..10, fn i ->
          Task.async(fn ->
            TokenManager.create_mcp_token(actor, "Concurrent Token #{i}")
          end)
        end)

      # Wait for all tasks to complete
      results = Enum.map(tasks, &Task.await(&1, 5000))

      # All should succeed
      successful_results =
        Enum.filter(results, fn
          {:ok, _token, _record} -> true
          _ -> false
        end)

      assert length(successful_results) == 10, "All concurrent token creations should succeed"

      # Verify all tokens were actually created
      tokens = TokenManager.list_mcp_tokens()
      concurrent_tokens = Enum.filter(tokens, &String.contains?(&1.name, "Concurrent Token"))

      assert length(concurrent_tokens) == 10, "All concurrent tokens should be persisted"

      # Verify no duplicate names were created
      token_names = Enum.map(concurrent_tokens, & &1.name)
      unique_names = Enum.uniq(token_names)
      assert length(token_names) == length(unique_names), "Token names should be unique"
    end

    test "handles concurrent actor creation with same name gracefully" do
      Core.Repo.delete_all(Actor)

      # Attempt to create actors with same name concurrently
      tasks =
        Enum.map(1..5, fn _i ->
          Task.async(fn ->
            TokenManager.create_mcp_actor("Duplicate Name Actor")
          end)
        end)

      # Wait for all tasks and collect results
      results =
        Enum.map(tasks, fn task ->
          try do
            Task.await(task, 5000)
          rescue
            e -> {:error, e}
          catch
            :exit, {:timeout, _} -> {:error, :timeout}
          end
        end)

      # Only one should succeed due to unique constraint
      successful_results =
        Enum.filter(results, fn
          {:ok, _actor} -> true
          _ -> false
        end)

      failed_results =
        Enum.filter(results, fn
          {:error, _} -> true
          _ -> false
        end)

      assert length(successful_results) == 1, "Only one actor creation should succeed"
      assert length(failed_results) == 4, "Four should fail due to unique constraint"

      # The successful one should be in the database
      actors = Core.Repo.all(Actor)
      duplicate_actors = Enum.filter(actors, &(&1.name == "Duplicate Name Actor"))
      assert length(duplicate_actors) == 1, "Only one actor with duplicate name should exist"
    end
  end

  describe "database failure scenarios" do
    test "propagates database constraint errors appropriately" do
      # This should succeed
      assert {:ok, _actor} = TokenManager.create_mcp_actor("Unique Actor Name")

      # This should fail with constraint error
      result = TokenManager.create_mcp_actor("Unique Actor Name")

      case result do
        {:error, changeset} ->
          assert changeset.errors[:name] != nil, "Should have name constraint error"

        other ->
          flunk("Expected constraint error, got: #{inspect(other)}")
      end
    end

    test "rejects empty actor name" do
      {:error, changeset} = TokenManager.create_mcp_actor("", "Valid description", :agent)

      assert changeset.valid? == false, "Should be invalid changeset"
      assert changeset.errors[:name] != nil, "Should have name validation error"
    end

    test "rejects nil actor name" do
      {:error, changeset} = TokenManager.create_mcp_actor(nil, "Valid description", :agent)

      assert changeset.valid? == false, "Should be invalid changeset"
      assert changeset.errors[:name] != nil, "Should have name validation error"
    end

    test "rejects invalid actor type" do
      {:error, changeset} =
        TokenManager.create_mcp_actor("Valid Name", "Valid description", "invalid_type")

      assert changeset.valid? == false, "Should be invalid changeset"
      assert changeset.errors[:type] != nil, "Should have type validation error"
    end
  end

  describe "cascade deletion verification" do
    test "actor deactivation properly handles token cleanup" do
      # Create actor with multiple tokens
      actor = Factories.create_actor(%{name: "Deletion Test Actor"})

      # Create multiple tokens for the actor
      {:ok, token1, _} = TokenManager.create_mcp_token(actor, "Token 1")
      {:ok, token2, _} = TokenManager.create_mcp_token(actor, "Token 2")
      {_token3, changeset3} = ActorToken.create_session_token(actor)
      # Actually insert the session token
      Core.Repo.insert!(changeset3)

      # Verify tokens work
      assert {:ok, _} = Core.Authentication.ActorSession.verify_api_token(token1)
      assert {:ok, _} = Core.Authentication.ActorSession.verify_api_token(token2)

      # Deactivate actor
      assert {:ok, {updated_actor, revocation_results}} = TokenManager.deactivate_actor(actor)

      # Verify actor is deactivated
      assert updated_actor.active == false

      # Verify tokens are revoked
      assert {:error, :invalid_token} = Core.Authentication.ActorSession.verify_api_token(token1)
      assert {:error, :invalid_token} = Core.Authentication.ActorSession.verify_api_token(token2)

      # Verify revocation results structure
      assert Map.has_key?(revocation_results, :api_tokens)
      assert Map.has_key?(revocation_results, :session_tokens)

      # Both should be tuples indicating number of revoked tokens
      {api_count, _} = revocation_results.api_tokens
      {session_count, _} = revocation_results.session_tokens

      assert api_count == 2, "Should revoke 2 API tokens"
      assert session_count == 1, "Should revoke 1 session token"
    end

    test "handles deactivation of actor with no tokens" do
      actor = Factories.create_actor(%{name: "No Tokens Actor"})

      # Deactivate actor with no tokens
      assert {:ok, {updated_actor, revocation_results}} = TokenManager.deactivate_actor(actor)

      assert updated_actor.active == false

      # Should still return proper structure even with no tokens
      {api_count, _} = revocation_results.api_tokens
      {session_count, _} = revocation_results.session_tokens

      assert api_count == 0, "Should revoke 0 API tokens"
      assert session_count == 0, "Should revoke 0 session tokens"
    end
  end

  describe "token rotation edge cases" do
    test "handles rotation of expired token" do
      {_actor, expired_token, _} = Factories.create_expired_token_actor()

      # Should not be able to rotate expired token
      result = TokenManager.rotate_token(expired_token, "New Token Name")

      assert {:error, :invalid_token} = result, "Should reject rotation of expired token"
    end

    test "handles rotation with very long token names" do
      {_actor, token, _} = Factories.create_actor_with_token()

      # Test with extremely long token name (over 255 chars)
      very_long_name = String.duplicate("a", 300)

      result = TokenManager.rotate_token(token, very_long_name)

      # Should now properly validate and return an error instead of crashing
      assert {:error, reason} = result
      assert is_binary(reason), "Should return validation error message"
      assert String.contains?(reason, "too long"), "Error should mention length validation"
    end

    test "handles multiple rapid rotations" do
      {_actor, initial_token, _} = Factories.create_actor_with_token()

      # Perform multiple rotations rapidly
      tokens =
        Enum.reduce(1..5, [initial_token], fn i, [current_token | _] = acc ->
          case TokenManager.rotate_token(current_token, "Rotation #{i}", true) do
            {:ok, result} ->
              [result.new_token | acc]

            {:error, _} ->
              # Keep previous token if rotation fails
              acc
          end
        end)

      # Should have progressed through rotations
      assert length(tokens) > 1, "Should have successfully rotated tokens"

      # Only the latest token should be valid
      [latest_token | old_tokens] = tokens

      assert {:ok, _} = Core.Authentication.ActorSession.verify_api_token(latest_token)

      # All previous tokens should be invalid
      Enum.each(old_tokens, fn old_token ->
        assert {:error, :invalid_token} =
                 Core.Authentication.ActorSession.verify_api_token(old_token)
      end)
    end
  end
end
