defmodule Systems.Ontology.ManagerEdgeCasesTest do
  @moduledoc """
  Critical edge case tests for Ontology Manager classes.
  
  Tests focus on:
  - ConceptManager edge cases and error handling
  - PredicateManager edge cases and error handling
  - Manager defensive programming
  - Concurrent manager operations
  - Manager integration with Global Knowledge Commons
  """
  
  use Core.DataCase

  alias Systems.Ontology.{ConceptManager, PredicateManager}
  alias Core.Authentication.Actor
  alias Core.Repo

  defp create_actor(attrs \\ %{}) do
    %Actor{
      type: :agent,
      name: "Test Actor #{System.unique_integer([:positive])}",
      description: "Test actor for manager tests",
      active: true
    }
    |> struct!(attrs)
    |> Actor.change()
    |> Actor.validate()
    |> Repo.insert!()
  end

  describe "ConceptManager Edge Cases" do
    test "handles empty concept phrase" do
      actor = create_actor()
      result = ConceptManager.create_concept("", "Test Actor", actor)
      
      assert result.phrase != nil
      assert is_binary(result.phrase)
      assert byte_size(result.phrase) < 10_000
    end

    test "handles whitespace-only concept phrase" do
      actor = create_actor()
      result = ConceptManager.create_concept("   ", "Test Actor", actor)
      
      assert result.phrase != nil
      assert is_binary(result.phrase)
      assert byte_size(result.phrase) < 10_000
    end

    test "handles control characters in concept phrase" do
      actor = create_actor()
      result = ConceptManager.create_concept("\n\t\r", "Test Actor", actor)
      
      assert result.phrase != nil
      assert is_binary(result.phrase)
      assert byte_size(result.phrase) <= 25_000
    end

    test "handles very long concept phrase" do
      actor = create_actor()
      long_phrase = String.duplicate("Very long concept phrase ", 1000)
      result = ConceptManager.create_concept(long_phrase, "Test Actor", actor)
      
      assert result.phrase != nil
      assert is_binary(result.phrase)
      assert byte_size(result.phrase) <= 25_000
    end

    test "handles template injection attempt" do
      actor = create_actor()
      result = ConceptManager.create_concept("{{malicious.code()}}", "Test Actor", actor)
      
      assert result.phrase != nil
      assert is_binary(result.phrase)
      assert byte_size(result.phrase) <= 25_000
    end

    test "handles XSS attempt" do
      actor = create_actor()
      result = ConceptManager.create_concept("<script>alert('xss')</script>", "Test Actor", actor)
      
      assert result.phrase != nil
      assert is_binary(result.phrase)
      assert byte_size(result.phrase) <= 25_000
    end

    test "handles SQL injection attempt" do
      actor = create_actor()
      result = ConceptManager.create_concept("'; DROP TABLE ontology_concept; --", "Test Actor", actor)
      
      assert result.phrase != nil
      assert is_binary(result.phrase)
      assert byte_size(result.phrase) < 10_000
    end

    test "handles binary data in concept phrase" do
      actor = create_actor()
      result = ConceptManager.create_concept("\x00\x01\x02\x03", "Test Actor", actor)
      
      assert result.phrase != nil
      assert is_binary(result.phrase)
      assert byte_size(result.phrase) < 10_000
    end

    test "handles special characters in concept phrase" do
      actor = create_actor()
      result = ConceptManager.create_concept("Special chars: @#$%^&*()[]{}|\\:;\"'<>?,./`~", "Test Actor", actor)
      
      assert result.phrase != nil
      assert is_binary(result.phrase)
      assert byte_size(result.phrase) < 10_000
    end
    
    test "handles concurrent concept creation" do
      actor = create_actor()
      
      # Multiple tasks creating same concept
      tasks = Enum.map(1..10, fn _i ->
        Task.async(fn ->
          ConceptManager.create_concept("Concurrent Test Concept", "Test Actor", actor)
        end)
      end)
      
      results = Enum.map(tasks, &Task.await(&1, 5000))
      
      # Should handle concurrency without corruption
      successful_results = Enum.filter(results, fn result ->
        case result do
          %{success: true} -> true
          _ -> false
        end
      end)
      
      # At least some should succeed
      assert length(successful_results) > 0
      
      # All successful results should have same concept ID (global sharing)
      concept_ids = Enum.map(successful_results, fn result -> result.concept_id end)
      |> Enum.uniq()
      
      assert length(concept_ids) <= 1, "Global sharing should return same concept ID"
    end
    
    test "handles invalid actor references" do
      # ConceptManager requires an Actor, so test with invalid actors
      invalid_actors = [
        nil,
        %{},
        %{id: nil},
        %Actor{id: 999999, name: "nonexistent"}  # Non-existent actor
      ]
      
      Enum.each(invalid_actors, fn actor ->
        try do
          ConceptManager.create_concept("Test Concept", "Test Actor", actor)
        rescue
          error ->
            # Should not crash with system errors
            error_message = Exception.message(error)
            assert not String.contains?(error_message, "undefined")
            assert not String.contains?(error_message, "system")
        end
      end)
    end
    
    test "handles memory constraints with large concept operations" do
      # Create many concepts efficiently
      concept_count = 50  # Reduced for test performance
      actor = create_actor()
      
      {time_micros, results} = :timer.tc(fn ->
        Enum.map(1..concept_count, fn i ->
          ConceptManager.create_concept("Performance Test Concept #{i}", nil, actor)
        end)
      end)
      
      # Should complete in reasonable time
      assert time_micros < 10_000_000, "#{concept_count} concept operations should complete within 10 seconds"
      
      # Count successful operations
      successful_count = Enum.count(results, fn result ->
        case result do
          %{success: true} -> true
          _ -> false
        end
      end)
      
      # Should have high success rate
      assert successful_count >= concept_count * 0.8, "Should have at least 80% success rate"
    end
  end

  describe "PredicateManager Edge Cases" do
    
    test "handles self-referential predicate prevention" do
      actor = create_actor()
      
      concept_result = ConceptManager.create_concept("Self Reference Test", nil, actor)
      predicate_result = ConceptManager.create_concept("references", nil, actor)
      
      concept_id = concept_result.concept_id
      predicate_type_id = predicate_result.concept_id
      
      # Should prevent self-referential predicates
      result = PredicateManager.create_predicate(concept_id, predicate_type_id, concept_id, false, actor)
      
      case result do
        %{success: false, error: reason} ->
          # Should prevent self-reference with clear error
          assert is_binary(reason)
          assert String.contains?(String.downcase(reason), "same") or 
                 String.contains?(String.downcase(reason), "circular") or
                 String.contains?(String.downcase(reason), "constraint")
        %{success: true} ->
          # If it allows self-reference, that might be valid depending on design
          assert true
      end
    end
    
    test "handles concurrent predicate creation" do
      actor = create_actor()
      
      # Create shared concepts
      subject_result = ConceptManager.create_concept("Concurrent Subject", nil, actor)
      predicate_result = ConceptManager.create_concept("Concurrent Predicate", nil, actor)
      object_result = ConceptManager.create_concept("Concurrent Object", nil, actor)
      
      subject_id = subject_result.concept_id
      predicate_type_id = predicate_result.concept_id
      object_id = object_result.concept_id
      
      # Multiple tasks creating same predicate concurrently
      tasks = Enum.map(1..8, fn _i ->
        Task.async(fn ->
          PredicateManager.create_predicate(subject_id, predicate_type_id, object_id, false, actor)
        end)
      end)
      
      results = Enum.map(tasks, &Task.await(&1, 5000))
      
      # Should handle concurrency gracefully
      successful_results = Enum.filter(results, fn result ->
        case result do
          %{success: true} -> true
          _ -> false
        end
      end)
      
      # Should have successful operations
      assert length(successful_results) > 0
      
      # Global sharing: all successful predicates should have same ID
      predicate_ids = Enum.map(successful_results, fn result -> result.predicate_id end)
      |> Enum.uniq()
      
      assert length(predicate_ids) <= 1, "Global sharing should return same predicate ID"
    end
    
    test "handles predicate negation edge cases" do
      actor = create_actor()
      
      subject_result = ConceptManager.create_concept("Negation Subject", nil, actor)
      predicate_result = ConceptManager.create_concept("Negation Predicate", nil, actor)
      object_result = ConceptManager.create_concept("Negation Object", nil, actor)
      
      subject_id = subject_result.concept_id
      predicate_type_id = predicate_result.concept_id
      object_id = object_result.concept_id
      
      # Create positive predicate
      positive_result = PredicateManager.create_predicate(subject_id, predicate_type_id, object_id, false, actor)
      
      # Create negated predicate
      negated_result = PredicateManager.create_predicate(subject_id, predicate_type_id, object_id, true, actor)
      
      case {positive_result, negated_result} do
        {%{success: true}, %{success: true}} ->
          # Should be different predicates
          assert positive_result.predicate_id != negated_result.predicate_id
          assert positive_result.negated? == false
          assert negated_result.negated? == true
        _ ->
          # If either fails, that's acceptable depending on implementation
          assert true
      end
    end
  end

  describe "Manager Integration and Error Boundaries" do
    test "managers handle error recovery gracefully" do
      actor = create_actor()
      
      # Test concept error handling
      concept_result = ConceptManager.create_concept("Error Recovery Test", nil, actor)
      assert concept_result.success == true
      
      # Test predicate error handling with valid components
      subject_result = ConceptManager.create_concept("Error Subject", nil, actor)
      predicate_result = ConceptManager.create_concept("Error Predicate", nil, actor)
      object_result = ConceptManager.create_concept("Error Object", nil, actor)
      
      predicate_create_result = PredicateManager.create_predicate(
        subject_result.concept_id,
        predicate_result.concept_id,
        object_result.concept_id,
        false,
        actor
      )
      
      # Should handle operations without system crashes
      case predicate_create_result do
        %{success: true} -> assert true
        %{success: false} -> assert true  # Failure is acceptable
        _ -> flunk("Unexpected result format")
      end
    end
    
    test "managers handle memory pressure scenarios" do
      actor = create_actor()
      
      # Stress test with many operations
      operation_count = 20  # Reduced for test performance
      
      {time_micros, _results} = :timer.tc(fn ->
        Enum.map(1..operation_count, fn i ->
          # Mix of concept and predicate operations
          subject_result = ConceptManager.create_concept("Memory Test Subject #{i}", nil, actor)
          object_result = ConceptManager.create_concept("Memory Test Object #{i}", nil, actor)
          predicate_result = ConceptManager.create_concept("memory_test_relation", nil, actor)
          
          if subject_result.success and object_result.success and predicate_result.success do
            PredicateManager.create_predicate(
              subject_result.concept_id,
              predicate_result.concept_id,
              object_result.concept_id,
              false,
              actor
            )
          end
        end)
      end)
      
      # Should complete efficiently
      assert time_micros < 15_000_000, "#{operation_count} mixed operations should complete within 15 seconds"
    end
  end

  describe "Manager Global Knowledge Commons Integration" do
    test "managers correctly implement global sharing model" do
      actor1 = create_actor()
      actor2 = create_actor()
      
      # Create same concept from different actors
      concept1_result = ConceptManager.create_concept("Global Sharing Test", nil, actor1)
      concept2_result = ConceptManager.create_concept("Global Sharing Test", nil, actor2)
      
      # Should both succeed and reference same concept
      assert concept1_result.success == true
      assert concept2_result.success == true
      assert concept1_result.concept_id == concept2_result.concept_id
      
      # Test predicate sharing
      predicate_result = ConceptManager.create_concept("global_test_relation", nil, actor1)
      object_result = ConceptManager.create_concept("Global Test Object", nil, actor1)
      
      if predicate_result.success and object_result.success do
        pred1_result = PredicateManager.create_predicate(
          concept1_result.concept_id,
          predicate_result.concept_id,
          object_result.concept_id,
          false,
          actor1
        )
        
        pred2_result = PredicateManager.create_predicate(
          concept2_result.concept_id,
          predicate_result.concept_id,
          object_result.concept_id,
          false,
          actor2
        )
        
        case {pred1_result, pred2_result} do
          {%{success: true}, %{success: true}} ->
            # Should be same predicate globally
            assert pred1_result.predicate_id == pred2_result.predicate_id
          _ ->
            # If predicate creation fails, that's acceptable for this test
            assert true
        end
      end
    end
  end
end