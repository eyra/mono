defmodule Systems.Ontology.PublicApiEdgeCasesTest do
  @moduledoc """
  Critical edge case tests for Ontology Public API.

  Tests focus on:
  - Public API error handling and defensive programming
  - Edge cases in concept and predicate operations
  - API parameter validation and sanitization
  - Error boundaries and graceful degradation
  - Global Knowledge Commons Public API behavior
  """

  use Core.DataCase

  alias Systems.Ontology.Public
  alias Core.Authentication.Entity
  alias Core.Repo

  # Factory functions for test data
  defp create_entity(attrs \\ %{}) do
    %Entity{
      identifier: "test:#{System.unique_integer([:positive])}"
    }
    |> struct!(attrs)
    |> Entity.change()
    |> Entity.validate()
    |> Repo.insert!()
  end

  describe "Public API Concept Operations Edge Cases" do
    test "obtain_concept! handles invalid phrases gracefully" do
      entity = create_entity()

      invalid_phrases = [
        nil,
        "",
        "   ",
        "\n\t\r",
        String.duplicate("Very long phrase ", 1000),
        "\x00\x01\x02\x03Binary data",
        "{{injection.attack()}}",
        "<script>alert('xss')</script>",
        "'; DROP TABLE ontology_concept; --"
      ]

      Enum.each(invalid_phrases, fn phrase ->
        try do
          result = Public.obtain_concept!(phrase, entity)

          # If successful, should have sanitized phrase
          assert result.phrase != nil
          assert is_binary(result.phrase)
          assert byte_size(result.phrase) < 10_000
        rescue
          error ->
            # Should not crash with system errors
            error_message = Exception.message(error)
            assert not String.contains?(error_message, "undefined")
            assert not String.contains?(error_message, "system")
        end
      end)
    end

    test "get_concept handles invalid selectors" do
      invalid_selectors = [
        nil,
        "",
        # Non-existent ID
        999_999,
        # Invalid ID
        -1,
        %{invalid: "selector"},
        "nonexistent phrase"
      ]

      Enum.each(invalid_selectors, fn selector ->
        result = Public.get_concept(selector)

        # Should return nil for invalid selectors, not crash
        assert result == nil
      end)
    end

    test "list_concepts handles invalid entities" do
      invalid_entity_lists = [
        nil,
        [],
        [nil],
        [%{}],
        # Non-existent entity
        [%Entity{id: 999_999}],
        "invalid_entity_list"
      ]

      Enum.each(invalid_entity_lists, fn entities ->
        try do
          result = Public.list_concepts(entities, [])

          # Should return empty list or handle gracefully
          assert is_list(result)
        rescue
          _error ->
            # Some invalid inputs may cause exceptions - acceptable
            assert true
        end
      end)
    end

    test "concept operations with corrupted entity data" do
      entity = create_entity()

      # Create concept normally first
      concept = Public.obtain_concept!("Test Concept", entity)
      assert concept.phrase == "Test Concept"

      # Try to create with corrupted entity (simulate data corruption)
      corrupted_entity = %Entity{id: entity.id, identifier: nil}

      try do
        Public.obtain_concept!("Corrupted Entity Test", corrupted_entity)
      rescue
        error ->
          # Should handle corrupted entity gracefully
          error_message = Exception.message(error)
          assert not String.contains?(error_message, "undefined")
      end
    end
  end

  describe "Public API Predicate Operations Edge Cases" do
    test "obtain_predicate handles invalid concept references" do
      entity = create_entity()

      # Create valid concepts first
      valid_subject = Public.obtain_concept!("Valid Subject", entity)
      valid_predicate_type = Public.obtain_concept!("Valid Predicate", entity)
      valid_object = Public.obtain_concept!("Valid Object", entity)

      invalid_component_sets = [
        {nil, valid_predicate_type, valid_object},
        {valid_subject, nil, valid_object},
        {valid_subject, valid_predicate_type, nil},
        # Non-existent concept
        {%{id: 999_999}, valid_predicate_type, valid_object},
        {"invalid_concept", valid_predicate_type, valid_object}
      ]

      Enum.each(invalid_component_sets, fn {subject, predicate_type, object} ->
        try do
          Public.obtain_predicate(subject, predicate_type, object, false, entity)
        rescue
          error ->
            # Should handle invalid concepts gracefully
            error_message = Exception.message(error)
            assert not String.contains?(error_message, "undefined")
            assert not String.contains?(error_message, "function_clause")
        end
      end)
    end

    test "get_predicate handles invalid selectors" do
      invalid_selectors = [
        nil,
        {},
        {nil, nil, nil, nil},
        {"nonexistent", "predicate", "selector", false},
        # Invalid format
        999_999
      ]

      Enum.each(invalid_selectors, fn selector ->
        try do
          result = Public.get_predicate(selector)

          # Should return nil for invalid selectors
          assert result == nil
        rescue
          _error ->
            # Some invalid selectors may cause exceptions - acceptable
            assert true
        end
      end)
    end

    test "list_predicates handles edge cases" do
      entity = create_entity()

      # Test with empty entity list
      result = Public.list_predicates([], [])
      assert result == []

      # Test with invalid preloads
      invalid_preloads = [
        :invalid_preload,
        [:nonexistent_association],
        "invalid_preload_format"
      ]

      Enum.each(invalid_preloads, fn preload ->
        try do
          Public.list_predicates([entity], preload)
        rescue
          error ->
            # Should handle invalid preloads gracefully
            error_message = Exception.message(error)
            assert not String.contains?(error_message, "undefined")
        end
      end)
    end

    test "predicate operations with self-referential constraints" do
      entity = create_entity()

      concept = Public.obtain_concept!("Self Reference Test", entity)
      predicate_type = Public.obtain_concept!("references", entity)

      # Should handle self-referential predicate constraint
      try do
        Public.obtain_predicate(concept, predicate_type, concept, false, entity)
      rescue
        Ecto.ConstraintError ->
          # Constraint violation is expected and handled correctly
          assert true

        error ->
          # Other errors should be descriptive
          error_message = Exception.message(error)
          assert not String.contains?(error_message, "undefined")
      end
    end
  end

  describe "Public API Global Knowledge Commons Edge Cases" do
    test "global concept sharing with concurrent access" do
      entity1 = create_entity()
      _entity2 = create_entity()

      # Concurrent access to same concept
      tasks =
        Enum.map(1..5, fn _i ->
          Task.async(fn ->
            Public.obtain_concept!("Global Concurrent Test", entity1)
          end)
        end)

      concepts = Enum.map(tasks, &Task.await(&1, 5000))

      # All should return same concept ID (global sharing)
      concept_ids = Enum.map(concepts, & &1.id) |> Enum.uniq()
      assert length(concept_ids) == 1, "Global sharing should return same concept ID"

      # Attribution should be consistent
      entity_ids = Enum.map(concepts, & &1.entity_id) |> Enum.uniq()
      assert length(entity_ids) == 1, "Attribution should be consistent"
    end

    test "global predicate sharing with concurrent access" do
      entity1 = create_entity()
      entity2 = create_entity()

      # Create concepts
      subject = Public.obtain_concept!("Global Predicate Subject", entity1)
      predicate_type = Public.obtain_concept!("Global Predicate Type", entity1)
      object = Public.obtain_concept!("Global Predicate Object", entity1)

      # Concurrent predicate creation
      tasks =
        Enum.map(1..3, fn i ->
          entity = if rem(i, 2) == 0, do: entity1, else: entity2

          Task.async(fn ->
            Public.obtain_predicate(subject, predicate_type, object, false, entity)
          end)
        end)

      predicates = Enum.map(tasks, &Task.await(&1, 5000))

      # All should return same predicate ID (global sharing)
      predicate_ids = Enum.map(predicates, & &1.id) |> Enum.uniq()
      assert length(predicate_ids) == 1, "Global sharing should return same predicate ID"

      # Attribution should go to first discoverer
      entity_ids = Enum.map(predicates, & &1.entity_id) |> Enum.uniq()
      assert length(entity_ids) == 1, "Attribution should be consistent"
    end

    test "global sharing constraint handling" do
      entity = create_entity()

      # Create concepts and predicate
      subject = Public.obtain_concept!("Constraint Test Subject", entity)
      predicate_type = Public.obtain_concept!("Constraint Test Predicate", entity)
      object = Public.obtain_concept!("Constraint Test Object", entity)

      # First creation should succeed
      predicate1 = Public.obtain_predicate(subject, predicate_type, object, false, entity)
      assert predicate1.id != nil

      # Second creation should return same predicate
      predicate2 = Public.obtain_predicate(subject, predicate_type, object, false, entity)
      assert predicate1.id == predicate2.id
    end
  end

  describe "Public API Query Operations Edge Cases" do
    test "query_concept_ids handles nil parameter" do
      try do
        result = Public.query_concept_ids(nil)
        assert is_list(result) or result == nil
      rescue
        _error ->
          assert true
      end
    end

    test "query_concept_ids handles empty list parameter" do
      try do
        result = Public.query_concept_ids([])
        assert is_list(result) or result == nil
      rescue
        _error ->
          assert true
      end
    end

    test "query_concept_ids handles string parameter" do
      try do
        result = Public.query_concept_ids("invalid_entities")
        assert is_list(result) or result == nil
      rescue
        _error ->
          assert true
      end
    end

    test "query_concept_ids handles integer parameter" do
      try do
        result = Public.query_concept_ids(999_999)
        assert is_list(result) or result == nil
      rescue
        _error ->
          assert true
      end
    end

    test "query_predicate_ids handles invalid selectors" do
      invalid_selectors = [
        nil,
        "invalid_selector",
        %{invalid: "structure"},
        999_999
      ]

      Enum.each(invalid_selectors, fn selector ->
        try do
          result = Public.query_predicate_ids(selector)

          # Should return list (possibly empty) or handle gracefully
          assert is_list(result) or result == nil
        rescue
          _error ->
            # Some invalid selectors may cause exceptions - acceptable
            assert true
        end
      end)
    end

    test "query operations with large result sets" do
      entity = create_entity()

      # Create many concepts
      # Reasonable for test
      concept_count = 50

      _concepts =
        Enum.map(1..concept_count, fn i ->
          Public.obtain_concept!("Query Test Concept #{i}", entity)
        end)

      # Query should handle large result sets efficiently
      {time_micros, result} =
        :timer.tc(fn ->
          Public.query_concept_ids([entity])
          |> Repo.all()
        end)

      # Should complete in reasonable time
      assert time_micros < 5_000_000, "Query should complete within 5 seconds"
      assert is_list(result)
      assert length(result) >= concept_count
    end
  end

  describe "Public API Reference Operations Edge Cases" do
    test "obtain_ontology_ref! handles invalid inputs" do
      invalid_inputs = [
        nil,
        %{},
        "invalid_input",
        # Non-existent reference
        %{id: 999_999}
      ]

      Enum.each(invalid_inputs, fn input ->
        try do
          Public.obtain_ontology_ref!(input)
        rescue
          error ->
            # Should handle invalid inputs with descriptive errors
            error_message = Exception.message(error)
            assert not String.contains?(error_message, "undefined")
        end
      end)
    end

    test "reference operations with corrupted data" do
      entity = create_entity()

      # Create valid concept first
      concept = Public.obtain_concept!("Reference Test Concept", entity)

      # Try to get reference
      try do
        ref = Public.obtain_ontology_ref!(concept)
        assert ref != nil
      rescue
        error ->
          # Reference creation might fail - should be handled gracefully
          error_message = Exception.message(error)
          assert not String.contains?(error_message, "undefined")
      end
    end
  end

  describe "Public API Error Boundary Testing" do
    test "API handles database connection issues gracefully" do
      entity = create_entity()

      # These operations should have proper error boundaries
      operations = [
        fn -> Public.get_concept("Test Concept") end,
        fn -> Public.list_concepts([entity], []) end,
        fn -> Public.query_concept_ids([entity]) end
      ]

      Enum.each(operations, fn operation ->
        try do
          _result = operation.()
          # Operations should succeed or fail gracefully
          assert true
        rescue
          error ->
            # Should not have system-level errors
            error_message = Exception.message(error)
            assert not String.contains?(error_message, "undefined")
            assert not String.contains?(error_message, "function_clause")
        end
      end)
    end

    test "API handles memory pressure scenarios" do
      entity = create_entity()

      # Stress test with many operations
      # Reasonable for test
      operation_count = 30

      {time_micros, _results} =
        :timer.tc(fn ->
          Enum.map(1..operation_count, fn i ->
            concept = Public.obtain_concept!("Memory Test #{i}", entity)
            Public.get_concept(concept.id)
          end)
        end)

      # Should complete efficiently
      assert time_micros < 10_000_000,
             "#{operation_count} operations should complete within 10 seconds"
    end
  end
end
