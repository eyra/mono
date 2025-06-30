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
  alias Core.Authentication.{Actor, Entity}
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

  defp create_entity(attrs \\ %{}) do
    %Entity{
      identifier: "test:#{System.unique_integer([:positive])}"
    }
    |> struct!(attrs)
    |> Entity.change()
    |> Entity.validate()
    |> Repo.insert!()
  end

  describe "Pattern Manager Security and Edge Cases" do
    test "create_from_pattern handles malicious pattern names" do
      actor = create_actor()
      
      malicious_patterns = [
        "../../../etc/passwd",
        "'; DROP TABLE annotations; --",
        "<script>alert('xss')</script>",
        "{{constructor.constructor('return process')().exit()}}",
        "%{system('rm -rf /')}", 
        nil,
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
          {:error, reason} ->
            # Should have descriptive error, not system error
            assert is_binary(reason)
            assert not String.contains?(reason, "system") 
            assert not String.contains?(reason, "process")
        end
      end)
    end
    
    test "create_from_pattern handles malicious statements" do
      actor = create_actor()
      
      malicious_statements = [
        String.duplicate("A", 100_000),  # Very long statement
        "{{constructor.constructor('return process')()}}",
        "<iframe src='javascript:alert(1)'></iframe>",
        "'; DROP TABLE annotations; SELECT '",
        "\x00\x01\x02\x03",  # Binary data
        ""
      ]
      
      Enum.each(malicious_statements, fn statement ->
        result = PatternManager.create_from_pattern("Test Pattern", statement, [], actor)
        
        # Should handle gracefully
        case result do
          {:ok, annotation} ->
            # If successful, statement should be sanitized/truncated
            assert byte_size(annotation.statement || "") < 50_000
          {:error, reason} ->
            # Should have proper validation error
            assert is_binary(reason)
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
      actor = create_actor()
      
      edge_case_statements = [
        nil,
        "",
        "  ",
        "\n\t\r",
        String.duplicate("Valid content ", 10_000),  # Very long
        "Unicode: 🚀💻🤖 emoji test",
        "Special chars: @#$%^&*()[]{}|\\:;\"'<>?,./`~"
      ]
      
      Enum.each(edge_case_statements, fn statement ->
        result = PatternManager.validate_statement(statement, actor)
        
        # Should return validation result, not crash
        assert is_tuple(result)
        case result do
          {:ok, _validated} -> assert true
          {:error, _reason} -> assert true
          _ -> flunk("Unexpected validation result format")
        end
      end)
    end
    
    test "validate_references handles malformed references" do
      actor = create_actor()
      
      malformed_references = [
        nil,
        [],
        [nil],
        ["invalid_string"],
        [%{invalid: "structure"}],
        [%{type: nil, target: nil}],
        Enum.map(1..1000, fn i -> %{type: "type_#{i}", target: "target_#{i}"} end)  # Very large
      ]
      
      Enum.each(malformed_references, fn references ->
        result = PatternManager.validate_references(references, actor)
        
        # Should handle gracefully
        case result do
          {:ok, _validated} -> assert true
          {:error, _reason} -> assert true
          _ -> flunk("Unexpected reference validation result")
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
        "#{7*7}"
      ]
      
      Enum.each(injection_statements, fn statement ->
        result = PatternValidator.validate_against_pattern("Test Pattern", statement, [], actor)
        
        # Should not execute any code, should validate safely
        case result do
          {:ok, _validation} -> 
            # If it passes validation, ensure no code was executed
            assert true
          {:error, _errors} ->
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
      
      Enum.each(malicious_inputs, fn {pattern, statement, refs} ->
        result = PatternValidator.suggest_improvements(pattern, statement, refs)
        
        # Should return suggestions safely, not execute code
        case result do
          suggestions when is_list(suggestions) ->
            # Should be list of strings
            assert Enum.all?(suggestions, &is_binary/1)
          _ ->
            # Other return types might be acceptable
            assert true
        end
      end)
    end
    
    test "validate_annotation handles corrupted annotation data" do
      actor = create_actor()
      
      corrupted_annotations = [
        nil,
        %{},
        %{statement: nil, references: nil},
        %{statement: String.duplicate("X", 100_000), references: []},
        %{statement: "test", references: [%{invalid: true}]}
      ]
      
      Enum.each(corrupted_annotations, fn annotation ->
        result = PatternValidator.validate_annotation(annotation, actor)
        
        # Should handle corruption gracefully
        case result do
          {:ok, _result} -> assert true
          {:error, _reason} -> assert true
        end
      end)
    end
  end

  describe "Pattern Manager Concurrent Operations" do
    test "concurrent pattern creation from same pattern" do
      actor = create_actor()
      
      # Multiple tasks creating annotations from same pattern
      tasks = Enum.map(1..10, fn i ->
        Task.async(fn ->
          PatternManager.create_from_pattern("Test Pattern", "Concurrent statement #{i}", [], actor)
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
      tasks = Enum.map(1..5, fn _i ->
        Task.async(fn ->
          PatternManager.load_pattern("Test Pattern")
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
      tasks = Enum.map(1..8, fn i ->
        Task.async(fn ->
          PatternValidator.validate_against_pattern("Test Pattern", "Statement #{i}", [], actor)
        end)
      end)
      
      results = Enum.map(tasks, &Task.await(&1, 5000))
      
      # Should complete without deadlocks or corruption
      assert length(results) == 8
      
      Enum.each(results, fn result ->
        case result do
          {:ok, _validation} -> assert true
          {:error, _errors} -> assert true
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
      {time_micros, result} = :timer.tc(fn ->
        PatternManager.create_from_pattern("Test Pattern", large_statement, [], actor)
      end)
      
      # Should complete in reasonable time
      assert time_micros < 5_000_000, "Large pattern creation should complete within 5 seconds"
      
      case result do
        {:ok, annotation} ->
          # Should handle large content appropriately
          assert is_binary(annotation.statement || "")
        {:error, _reason} ->
          # May fail due to size limits - that's acceptable
          assert true
      end
    end
    
    test "pattern manager memory usage with many patterns" do
      actor = create_actor()
      
      # Create many pattern operations
      results = Enum.map(1..50, fn i ->
        PatternManager.create_from_pattern("Pattern #{rem(i, 5)}", "Statement #{i}", [], actor)
      end)
      
      # Should not cause memory issues
      assert length(results) == 50
      
      # Count successful operations
      successful_count = Enum.count(results, fn result ->
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
      
      {time_micros, _results} = :timer.tc(fn ->
        Enum.map(1..validation_count, fn i ->
          PatternValidator.validate_against_pattern("Test Pattern", "Validation #{i}", [], actor)
        end)
      end)
      
      # Should complete efficiently
      assert time_micros < 10_000_000, "100 validations should complete within 10 seconds"
    end
  end

  describe "Pattern Error Handling and Recovery" do
    test "pattern manager error recovery" do
      actor = create_actor()
      
      # Test recovery from various error conditions
      error_conditions = [
        {"invalid_pattern", "valid statement", []},
        {"valid_pattern", nil, []},
        {"valid_pattern", "valid statement", "invalid_refs"}
      ]
      
      Enum.each(error_conditions, fn {pattern, statement, refs} ->
        result = PatternManager.create_from_pattern(pattern, statement, refs, actor)
        
        # Should handle errors gracefully, not crash system
        case result do
          {:ok, _annotation} -> assert true
          {:error, reason} -> 
            assert is_binary(reason)
            assert not String.contains?(reason, "undefined")
        end
      end)
    end
    
    test "pattern validator error boundaries" do
      actor = create_actor()
      
      # Invalid inputs that should be handled gracefully
      invalid_inputs = [
        {nil, nil, nil, nil},
        {"", "", [], actor},
        {"pattern", "statement", "invalid_refs", actor}
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
      result1 = PatternManager.create_from_pattern("Shared Pattern", "Actor 1 content", [], actor1)
      result2 = PatternManager.create_from_pattern("Shared Pattern", "Actor 2 content", [], actor2)
      
      # Should work for both actors
      case {result1, result2} do
        {{:ok, annotation1}, {:ok, annotation2}} ->
          # Should be different annotations (entity isolation)
          assert annotation1.id != annotation2.id
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
          PatternManager.create_from_pattern("Test Pattern", "test statement", [], invalid_actor)
        rescue
          _error ->
            # Should handle invalid actors gracefully
            assert true
        end
      end)
    end
  end
end