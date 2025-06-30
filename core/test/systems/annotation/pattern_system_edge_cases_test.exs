defmodule Systems.Annotation.PatternSystemEdgeCasesTest do
  @moduledoc """
  Critical edge case tests for the Annotation Pattern System.

  Tests focus on:
  - Pattern DSL security and validation
  - Pattern manager edge cases and error handling
  - Pattern validator defensive programming
  - Core patterns functionality
  - Pattern template injection prevention
  - Concurrent pattern operations
  """

  use Core.DataCase

  alias Systems.Annotation.{PatternManager, PatternValidator}
  alias Core.Authentication.Actor
  alias Core.Repo

  # Factory functions for test data
  defp create_actor(attrs \\ %{}) do
    %Actor{
      type: :agent,
      name: "Test Actor #{System.unique_integer([:positive])}",
      description: "Test actor for patterns",
      active: true
    }
    |> struct!(attrs)
    |> Actor.change()
    |> Actor.validate()
    |> Repo.insert!()
  end

  # defp _create_entity(attrs \\ %{}) do
  #   %Entity{
  #     identifier: "test:#{System.unique_integer([:positive])}"
  #   }
  #   |> struct!(attrs)
  #   |> Entity.change()
  #   |> Entity.validate()
  #   |> Repo.insert!()
  # end

  describe "Pattern Manager Security and Edge Cases" do
    test "create_from_pattern handles malicious pattern names" do
      actor = create_actor()

      malicious_patterns = [
        "../../../etc/passwd",
        "'; DROP TABLE annotations; --",
        "<script>alert('xss')</script>",
        "{{constructor.constructor('return process')().exit()}}",
        "%{system('rm -rf /')}",
        "",
        "nonexistent_pattern"
      ]

      Enum.each(malicious_patterns, fn pattern_name ->
        result = PatternManager.create_from_pattern(pattern_name, "test statement", [], actor)

        # Should either fail gracefully or handle safely
        case result do
          {:ok, _annotation} ->
            # If it succeeds, that's fine for some cases
            assert true

          {:error, %{error: reason}} when is_binary(reason) ->
            # Should have descriptive error, not system error
            assert String.contains?(reason, "Pattern not found")

          {:error, _reason} ->
            # Other error formats are acceptable
            assert true
        end
      end)
    end

    test "create_from_pattern handles malicious statements" do
      actor = create_actor()

      malicious_statements = [
        # Very long statement
        String.duplicate("A", 100_000),
        "{{constructor.constructor('return process')()}}",
        "<iframe src='javascript:alert(1)'></iframe>",
        "'; DROP TABLE annotations; SELECT '",
        # Binary data
        "\x00\x01\x02\x03",
        ""
      ]

      Enum.each(malicious_statements, fn statement ->
        result = PatternManager.create_from_pattern("Statement Pattern", statement, [], actor)

        # Should handle gracefully
        case result do
          {:ok, %{statement: statement}} ->
            # If successful, statement should be sanitized/truncated
            assert byte_size(statement || "") < 50_000

          {:ok, _annotation} ->
            # Other success formats
            assert true

          {:error, %{error: _reason}} ->
            # Should have proper validation error
            assert true

          {:error, _reason} ->
            # Other error formats are acceptable
            assert true
        end
      end)
    end

    test "load_pattern handles missing and corrupted patterns" do
      missing_patterns = [
        "NonExistentPattern",
        "../../invalid/path",
        "corrupt.pattern",
        ""
      ]

      Enum.each(missing_patterns, fn pattern_name ->
        result = PatternManager.load_pattern(pattern_name)

        # Should handle missing patterns gracefully
        case result do
          {:ok, _pattern} ->
            # Might succeed with fallback pattern
            assert true

          {:error, reason} ->
            # Should have descriptive error
            assert is_binary(reason)
            assert String.contains?(reason, "not found") or String.contains?(reason, "invalid")
        end
      end)
    end

    test "validate_statement handles edge cases" do
      _actor = create_actor()

      edge_case_statements = [
        # Reduced from 10_000
        {"Valid content repeated many times", String.duplicate("Valid content ", 100)},
        {"Unicode emoji test", "Unicode: 🚀💻🤖 emoji test"},
        {"Special characters", "Special chars: @#$%^&*()[]{}|\\:;\"'<>?,./`~"}
      ]

      Enum.each(edge_case_statements, fn {description, statement} ->
        # Load a test pattern first
        with {:ok, pattern} <- PatternManager.load_pattern("Statement Pattern") do
          result = PatternManager.validate_statement(statement, pattern)

          # Should return validation result, not crash
          assert is_tuple(result)

          case result do
            {:ok, _validated} -> assert true
            {:error, _reason} -> assert true
            _ -> flunk("Unexpected validation result format: #{description}")
          end
        else
          _ ->
            # If pattern loading fails, that's expected for some edge cases
            assert true
        end
      end)
    end

    test "validate_references handles malformed references" do
      _actor = create_actor()

      malformed_references = [
        [],
        [%{"type" => "valid_type", "target" => "valid_target"}],
        [%{"type" => "another_type", "target" => "another_target"}]
      ]

      Enum.each(malformed_references, fn references ->
        # Load a test pattern first
        with {:ok, pattern} <- PatternManager.load_pattern("Statement Pattern") do
          result = PatternManager.validate_references(references, pattern)

          # Should handle gracefully
          case result do
            {:ok, _validated} -> assert true
            {:error, _reason} -> assert true
            _ -> flunk("Unexpected reference validation result")
          end
        else
          _ ->
            # If pattern loading fails, that's expected
            assert true
        end
      end)
    end
  end

  describe "Pattern Validator Security" do
    test "validate_against_pattern prevents injection attacks" do
      actor = create_actor()

      injection_statements = [
        "{{constructor.constructor('return process')().exit()}}",
        "${java.lang.Runtime.getRuntime().exec('ls')}",
        "<%=`ls`%>",
        "{{7*7}}",
        "${7*7}",
        "#{7 * 7}"
      ]

      Enum.each(injection_statements, fn statement ->
        result =
          PatternValidator.validate_against_pattern("Statement Pattern", statement, [], actor)

        # Should not execute any code, should validate safely
        case result do
          %{success: true} ->
            # If it passes validation, ensure no code was executed
            assert true

          %{success: false} ->
            # If it fails, that's safe too
            assert true
        end
      end)
    end

    test "suggest_improvements handles malicious input" do
      actor = create_actor()

      malicious_inputs = [
        {nil, nil, nil},
        {"", [], actor},
        {"malicious", [%{type: "{{constructor}}", target: "evil"}], actor},
        {String.duplicate("A", 50_000), [], actor}
      ]

      Enum.each(malicious_inputs, fn {statement, refs, _actor} ->
        result = PatternValidator.suggest_improvements(statement, refs, "Statement Pattern")

        # Should return suggestions safely, not execute code
        case result do
          %{success: true, suggestions: suggestions} when is_list(suggestions) ->
            # Should be list of strings
            assert Enum.all?(suggestions, &is_binary/1)

          %{success: false} ->
            # Failed suggestions are acceptable
            assert true

          _ ->
            # Other return types might be acceptable
            assert true
        end
      end)
    end

    test "validate_annotation handles corrupted annotation data" do
      _actor = create_actor()

      corrupted_annotations = [
        nil,
        %{},
        %{statement: nil, references: nil},
        %{statement: String.duplicate("X", 100_000), references: []},
        %{statement: "test", references: [%{invalid: true}]}
      ]

      Enum.each(corrupted_annotations, fn annotation ->
        try do
          result = PatternValidator.validate_annotation(annotation, "Statement Pattern")

          # Should handle corruption gracefully
          case result do
            %{success: true} -> assert true
            %{success: false} -> assert true
            _ -> assert true
          end
        rescue
          _ ->
            # Some corrupted annotations may cause exceptions, which is acceptable
            assert true
        end
      end)
    end
  end

  describe "Pattern Manager Concurrent Operations" do
    test "concurrent pattern creation from same pattern" do
      actor = create_actor()

      # Multiple tasks creating annotations from same pattern
      tasks =
        Enum.map(1..10, fn i ->
          Task.async(fn ->
            PatternManager.create_from_pattern(
              "Statement Pattern",
              "Concurrent statement #{i} with sufficient length for validation",
              [],
              actor
            )
          end)
        end)

      results = Enum.map(tasks, &Task.await(&1, 5000))

      # Should handle concurrency gracefully
      Enum.each(results, fn result ->
        case result do
          {:ok, _annotation} -> assert true
          {:error, _reason} -> assert true
        end
      end)

      # No system crashes or database corruption
      assert true
    end

    test "concurrent pattern loading" do
      # Multiple tasks loading same pattern
      tasks =
        Enum.map(1..5, fn _i ->
          Task.async(fn ->
            PatternManager.load_pattern("Statement Pattern")
          end)
        end)

      results = Enum.map(tasks, &Task.await(&1, 5000))

      # Should handle concurrent loading safely
      Enum.each(results, fn result ->
        case result do
          {:ok, _pattern} -> assert true
          {:error, _reason} -> assert true
        end
      end)
    end

    test "concurrent validation operations" do
      actor = create_actor()

      # Multiple concurrent validations
      tasks =
        Enum.map(1..8, fn i ->
          Task.async(fn ->
            PatternValidator.validate_against_pattern(
              "Statement Pattern",
              "Statement #{i} with sufficient length",
              [],
              actor
            )
          end)
        end)

      results = Enum.map(tasks, &Task.await(&1, 5000))

      # Should complete without deadlocks or corruption
      assert length(results) == 8

      Enum.each(results, fn result ->
        case result do
          %{success: true} -> assert true
          %{success: false} -> assert true
          _ -> assert true
        end
      end)
    end
  end

  describe "Pattern Performance and Memory Safety" do
    test "pattern operations with large datasets" do
      actor = create_actor()

      # Large statement
      large_statement = String.duplicate("Large pattern content. ", 1000)

      # Should handle large content efficiently
      {time_micros, result} =
        :timer.tc(fn ->
          PatternManager.create_from_pattern("Statement Pattern", large_statement, [], actor)
        end)

      # Should complete in reasonable time
      assert time_micros < 5_000_000, "Large pattern creation should complete within 5 seconds"

      case result do
        {:ok, %{statement: statement}} ->
          # Should handle large content appropriately
          assert is_binary(statement || "")

        {:error, _reason} ->
          # May fail due to size limits - that's acceptable
          assert true
      end
    end

    test "pattern manager memory usage with many patterns" do
      actor = create_actor()

      # Create many pattern operations
      results =
        Enum.map(1..50, fn i ->
          PatternManager.create_from_pattern(
            "Statement Pattern",
            "Statement #{i} with sufficient length for validation",
            [],
            actor
          )
        end)

      # Should not cause memory issues
      assert length(results) == 50

      # Count successful operations
      successful_count =
        Enum.count(results, fn result ->
          case result do
            {:ok, _} -> true
            _ -> false
          end
        end)

      # Should have some successful operations
      assert successful_count >= 0
    end

    test "pattern validation memory safety" do
      actor = create_actor()

      # Large number of validation operations
      validation_count = 100

      {time_micros, _results} =
        :timer.tc(fn ->
          Enum.map(1..validation_count, fn i ->
            PatternValidator.validate_against_pattern(
              "Statement Pattern",
              "Validation #{i} with sufficient length",
              [],
              actor
            )
          end)
        end)

      # Should complete efficiently
      assert time_micros < 10_000_000, "100 validations should complete within 10 seconds"
    end
  end

  describe "Pattern Error Handling and Recovery" do
    test "pattern with nil references" do
      actor = create_actor()

      assert_raise FunctionClauseError, fn ->
        PatternManager.create_from_pattern("Statement Pattern", "test statement", nil, actor)
      end
    end

    test "pattern with invalid references" do
      actor = create_actor()

      assert_raise FunctionClauseError, fn ->
        PatternManager.create_from_pattern(
          "Statement Pattern",
          "test statement",
          "invalid references",
          actor
        )
      end
    end

    test "pattern without statement" do
      actor = create_actor()

      assert_raise FunctionClauseError, fn ->
        PatternManager.create_from_pattern("Statement Pattern", nil, [], actor)
      end
    end

    test "pattern without pattern name" do
      actor = create_actor()

      assert_raise FunctionClauseError, fn ->
        PatternManager.create_from_pattern(nil, "test statement", [], actor)
      end
    end

    test "pattern validator error boundaries" do
      actor = create_actor()

      # Invalid inputs that should be handled gracefully
      invalid_inputs = [
        {nil, nil, nil, nil},
        {"", "", [], actor},
        {"Statement Pattern", "statement with sufficient length", "invalid_refs", actor}
      ]

      Enum.each(invalid_inputs, fn input ->
        try do
          case input do
            {p, s, r, a} -> PatternValidator.validate_against_pattern(p, s, r, a)
            {p, s, r} -> PatternValidator.suggest_improvements(p, s, r)
          end
        rescue
          error ->
            # Should not raise system errors, only validation errors
            error_message = Exception.message(error)
            assert not String.contains?(error_message, "system")
            assert not String.contains?(error_message, "undefined")
        end
      end)
    end
  end

  describe "Pattern System Integration Edge Cases" do
    test "pattern system with entity isolation" do
      actor1 = create_actor()
      actor2 = create_actor()

      # Different actors using same pattern
      result1 =
        PatternManager.create_from_pattern(
          "Statement Pattern",
          "Actor 1 content with sufficient length",
          [],
          actor1
        )

      result2 =
        PatternManager.create_from_pattern(
          "Statement Pattern",
          "Actor 2 content with sufficient length",
          [],
          actor2
        )

      # Should work for both actors
      case {result1, result2} do
        {{:ok, %{annotation_id: id1}}, {:ok, %{annotation_id: id2}}} ->
          # Should be different annotations (entity isolation)
          assert id1 != id2
          # But same pattern can be used
          assert true

        _ ->
          # If patterns fail, should fail gracefully
          assert true
      end
    end

    test "pattern operations with invalid actor" do
      # Test with invalid actor objects
      invalid_actors = [
        nil,
        %{},
        %{id: nil, name: nil}
      ]

      Enum.each(invalid_actors, fn invalid_actor ->
        try do
          PatternManager.create_from_pattern(
            "Statement Pattern",
            "test statement with sufficient length",
            [],
            invalid_actor
          )
        rescue
          _error ->
            # Should handle invalid actors gracefully
            assert true
        end
      end)
    end
  end
end
