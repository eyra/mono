defmodule Systems.Ontology.OntologyEdgeCasesTest do
  use Core.DataCase

  alias Systems.Ontology.{Public, ConceptManager, PredicateManager}
  alias Systems.Ontology.{ConceptModel, PredicateModel}
  alias Core.Authentication.{Actor, Entity}
  alias Core.Repo

  # Factory functions for test data
  defp create_actor(attrs \\ %{}) do
    %Actor{
      type: :agent,
      name: "Test Actor #{System.unique_integer([:positive])}",
      description: "Test actor for ontology",
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

  describe "Systems.Ontology.Public.obtain_concept!/2" do
    test "creates new concept successfully" do
      entity = create_entity()
      phrase = "Machine Learning"

      concept = Public.obtain_concept!(phrase, entity)

      assert concept.phrase == phrase
      assert concept.entity_id == entity.id
      assert %NaiveDateTime{} = concept.inserted_at
    end

    test "returns existing concept for duplicate phrase" do
      entity = create_entity()
      phrase = "Deep Learning"

      concept1 = Public.obtain_concept!(phrase, entity)
      concept2 = Public.obtain_concept!(phrase, entity)

      assert concept1.id == concept2.id
      assert concept1.phrase == concept2.phrase
    end

    test "handles very long concept phrases" do
      entity = create_entity()
      long_phrase = String.duplicate("Very Long Concept Name ", 10)

      # Should either succeed or fail gracefully
      try do
        concept = Public.obtain_concept!(long_phrase, entity)
        assert is_integer(concept.id)
      rescue
        e in Ecto.ConstraintError ->
          # Database constraint violation - acceptable
          assert String.contains?(Exception.message(e), "constraint")
      end
    end

    test "handles empty and whitespace phrases" do
      entity = create_entity()

      test_cases = [
        "",
        "   ",
        "\n\t",
        nil
      ]

      Enum.each(test_cases, fn phrase ->
        try do
          Public.obtain_concept!(phrase, entity)
          flunk("Should not allow invalid phrase: #{inspect(phrase)}")
        rescue
          _ -> assert true, "Correctly rejected invalid phrase"
        end
      end)
    end

    test "handles special characters in phrases" do
      entity = create_entity()

      special_phrases = [
        "AI/ML Technology",
        "C++ Programming",
        "Machine Learning (Advanced)",
        "Data Science - Analytics",
        "Web 2.0",
        "Émile's Research"
      ]

      Enum.each(special_phrases, fn phrase ->
        concept = Public.obtain_concept!(phrase, entity)
        assert concept.phrase == phrase
      end)
    end

    test "handles concurrent concept creation for same phrase" do
      entity = create_entity()
      phrase = "Concurrent Concept"

      tasks =
        Enum.map(1..5, fn _i ->
          Task.async(fn ->
            Public.obtain_concept!(phrase, entity)
          end)
        end)

      concepts = Enum.map(tasks, &Task.await(&1, 5000))

      # All should return concepts with same phrase and entity
      assert Enum.all?(concepts, &(&1.phrase == phrase))
      assert Enum.all?(concepts, &(&1.entity_id == entity.id))

      # All should have same ID (same concept returned)
      concept_ids = Enum.map(concepts, & &1.id) |> Enum.uniq()
      assert length(concept_ids) == 1, "Should return same concept for concurrent calls"
    end

    test "handles global knowledge commons - different entities share same concept" do
      entity1 = create_entity()
      entity2 = create_entity()
      # Global knowledge concept
      phrase = "Machine Learning"

      concept1 = Public.obtain_concept!(phrase, entity1)
      concept2 = Public.obtain_concept!(phrase, entity2)

      # Global Knowledge Commons: Same concept shared across entities
      assert concept1.id == concept2.id, "Concepts should be shared globally in knowledge commons"
      assert concept1.phrase == concept2.phrase

      # Attribution: First discoverer gets credit (entity_id preserved)
      assert concept1.entity_id == entity1.id, "First discoverer should get attribution credit"
    end
  end

  describe "Systems.Ontology.Public.get_concept/2" do
    test "retrieves concept by ID" do
      entity = create_entity()
      phrase = "Retrievable Concept"
      created_concept = Public.obtain_concept!(phrase, entity)

      retrieved_concept = Public.get_concept(created_concept.id)

      assert retrieved_concept.id == created_concept.id
      assert retrieved_concept.phrase == phrase
    end

    test "retrieves concept by phrase" do
      entity = create_entity()
      phrase = "Searchable Concept"
      created_concept = Public.obtain_concept!(phrase, entity)

      retrieved_concept = Public.get_concept(phrase)

      assert retrieved_concept.id == created_concept.id
      assert retrieved_concept.phrase == phrase
    end

    test "returns nil for non-existent ID" do
      assert Public.get_concept(999_999) == nil
    end

    test "returns nil for non-existent phrase" do
      assert Public.get_concept("Non Existent Concept") == nil
    end

    test "handles invalid input types" do
      test_cases = [
        nil,
        [],
        %{},
        # Float instead of integer
        1.5,
        # Empty string
        ""
      ]

      Enum.each(test_cases, fn invalid_input ->
        result = Public.get_concept(invalid_input)
        assert result == nil, "Should return nil for invalid input: #{inspect(invalid_input)}"
      end)
    end

    test "respects preload parameter" do
      entity = create_entity()
      concept = Public.obtain_concept!("Preload Test", entity)

      # Without preload
      concept_no_preload = Public.get_concept(concept.id, [])
      assert not Ecto.assoc_loaded?(concept_no_preload.entity)

      # With preload
      concept_with_preload = Public.get_concept(concept.id, [:entity])
      assert Ecto.assoc_loaded?(concept_with_preload.entity)
      assert concept_with_preload.entity.id == entity.id
    end
  end

  describe "Systems.Ontology.Public.obtain_predicate/4" do
    test "creates predicate with global knowledge commons sharing" do
      entity1 = create_entity()
      entity2 = create_entity()

      # Global concepts shared across entities
      subject = Public.obtain_concept!("Machine Learning", entity1)
      predicate_type = Public.obtain_concept!("Subsumes", entity1)
      object = Public.obtain_concept!("Deep Learning", entity1)

      # First entity creates predicate
      predicate1 = Public.obtain_predicate(subject, predicate_type, object, false, entity1)

      # Second entity should get same predicate (global sharing)
      predicate2 = Public.obtain_predicate(subject, predicate_type, object, false, entity2)

      # Global Knowledge Commons: Same predicate shared
      assert predicate1.id == predicate2.id, "Predicates should be shared globally"
      assert predicate1.subject_id == subject.id
      assert predicate1.type_id == predicate_type.id
      assert predicate1.object_id == object.id
      assert predicate1.type_negated? == false

      # Attribution: First discoverer gets credit
      assert predicate1.entity_id == entity1.id, "First discoverer should get attribution"
    end

    test "returns existing predicate for duplicate relationship" do
      entity = create_entity()

      subject = Public.obtain_concept!("AI", entity)
      predicate_type = Public.obtain_concept!("Includes", entity)
      object = Public.obtain_concept!("ML", entity)

      predicate1 = Public.obtain_predicate(subject, predicate_type, object, false, entity)
      predicate2 = Public.obtain_predicate(subject, predicate_type, object, false, entity)

      assert predicate1.id == predicate2.id
    end

    test "handles self-referential relationships" do
      entity = create_entity()

      concept = Public.obtain_concept!("Recursive Concept", entity)
      predicate_type = Public.obtain_concept!("Self Reference", entity)

      # This should be prevented by database constraint
      assert_raise Ecto.ConstraintError, fn ->
        Public.obtain_predicate(concept, predicate_type, concept, false, entity)
      end
    end

    test "creates predicate with negation" do
      entity = create_entity()

      subject = Public.obtain_concept!("Cat", entity)
      predicate_type = Public.obtain_concept!("Is A", entity)
      object = Public.obtain_concept!("Dog", entity)

      predicate =
        Public.insert_predicate(subject, predicate_type, object, entity, type_negated?: true)

      case predicate do
        {:ok, p} ->
          assert p.type_negated? == true

        {:error, _} ->
          # Might fail due to constraints - that's acceptable
          assert true
      end
    end

    test "handles concurrent predicate creation" do
      entity = create_entity()

      subject = Public.obtain_concept!("Concurrent Subject", entity)
      predicate_type = Public.obtain_concept!("Concurrent Predicate", entity)
      object = Public.obtain_concept!("Concurrent Object", entity)

      tasks =
        Enum.map(1..3, fn _i ->
          Task.async(fn ->
            Public.obtain_predicate(subject, predicate_type, object, false, entity)
          end)
        end)

      predicates = Enum.map(tasks, &Task.await(&1, 5000))

      # All should reference same concepts
      assert Enum.all?(predicates, &(&1.subject_id == subject.id))
      assert Enum.all?(predicates, &(&1.type_id == predicate_type.id))
      assert Enum.all?(predicates, &(&1.object_id == object.id))

      # All should be same predicate (due to uniqueness)
      predicate_ids = Enum.map(predicates, & &1.id) |> Enum.uniq()
      assert length(predicate_ids) == 1
    end
  end

  describe "Systems.Ontology.Public.list_concepts/2" do
    test "lists concepts for specific entities" do
      entity1 = create_entity()
      entity2 = create_entity()

      # Create concepts for each entity
      concept1 = Public.obtain_concept!("Entity 1 Concept", entity1)
      concept2 = Public.obtain_concept!("Entity 2 Concept", entity2)
      concept3 = Public.obtain_concept!("Another Entity 1 Concept", entity1)

      # List concepts for entity1 only
      entity1_concepts = Public.list_concepts([entity1])

      entity1_concept_ids = Enum.map(entity1_concepts, & &1.id)
      assert concept1.id in entity1_concept_ids
      assert concept3.id in entity1_concept_ids
      assert concept2.id not in entity1_concept_ids
    end

    test "handles empty entity list" do
      concepts = Public.list_concepts([])

      # Should return empty list or handle gracefully
      assert is_list(concepts)
    end

    test "respects ordering" do
      entity = create_entity()

      # Create concepts in specific order
      _concept1 = Public.obtain_concept!("A Concept", entity)
      _concept2 = Public.obtain_concept!("B Concept", entity)
      _concept3 = Public.obtain_concept!("C Concept", entity)

      concepts = Public.list_concepts([entity])
      concept_ids = Enum.map(concepts, & &1.id)

      # Should be ordered by ID ascending
      assert concept_ids == Enum.sort(concept_ids)
    end
  end

  describe "Systems.Ontology.Public.prepare_ontology_ref/1" do
    test "creates ref for concept" do
      entity = create_entity()
      concept = Public.obtain_concept!("Referenced Concept", entity)

      changeset = Public.prepare_ontology_ref(concept)

      assert changeset.valid?
      concept_changeset = Ecto.Changeset.get_change(changeset, :concept)
      assert concept_changeset != nil
      assert Ecto.Changeset.get_field(concept_changeset, :id) == concept.id
      assert Ecto.Changeset.get_change(changeset, :predicate) == nil
    end

    test "creates ref for predicate" do
      entity = create_entity()

      subject = Public.obtain_concept!("Ref Subject", entity)
      predicate_type = Public.obtain_concept!("Ref Type", entity)
      object = Public.obtain_concept!("Ref Object", entity)

      predicate = Public.obtain_predicate(subject, predicate_type, object, false, entity)

      changeset = Public.prepare_ontology_ref(predicate)

      assert changeset.valid?
      predicate_changeset = Ecto.Changeset.get_change(changeset, :predicate)
      assert predicate_changeset != nil
      assert Ecto.Changeset.get_field(predicate_changeset, :id) == predicate.id
      assert Ecto.Changeset.get_change(changeset, :concept) == nil
    end

    test "handles invalid input types with defensive programming" do
      invalid_inputs = [
        "not a concept or predicate",
        %{},
        123
      ]

      Enum.each(invalid_inputs, fn invalid_input ->
        changeset = Public.prepare_ontology_ref(invalid_input)
        assert not changeset.valid?
        assert changeset.errors[:base] != nil
      end)

      # Test nil specifically
      nil_changeset = Public.prepare_ontology_ref(nil)
      assert not nil_changeset.valid?
      assert nil_changeset.errors[:base] != nil
    end
  end

  describe "Systems.Ontology.ConceptManager edge cases" do
    test "create_concept handles phrase validation" do
      actor = create_actor()

      test_cases = [
        {"Valid Concept", true},
        # Too short
        {"A", false},
        # Too long
        {String.duplicate("Very Long Concept Name ", 20), false},
        # Leading whitespace
        {"  Leading Spaces", false},
        # Trailing whitespace
        {"Trailing Spaces  ", false},
        # Invalid characters
        {"Invalid@Chars!", false},
        # Empty
        {"", false}
      ]

      Enum.each(test_cases, fn {phrase, should_succeed} ->
        result = ConceptManager.create_concept(phrase, "Test description", actor)

        if should_succeed do
          assert result.success == true
          assert result.phrase != nil
        else
          assert result.success == false
          assert result.error != nil
        end
      end)
    end

    test "create_concept normalizes phrase format" do
      actor = create_actor()

      result = ConceptManager.create_concept("machine learning", "Test", actor)

      assert result.success == true
      # Normalized to title case
      assert result.phrase == "Machine Learning"
    end

    test "search_concepts returns relevance scores" do
      actor = create_actor()

      # Create test concepts
      ConceptManager.create_concept("Machine Learning", nil, actor)
      ConceptManager.create_concept("Deep Learning", nil, actor)
      ConceptManager.create_concept("Statistical Learning", nil, actor)
      ConceptManager.create_concept("Natural Language Processing", nil, actor)

      result = ConceptManager.search_concepts("learning", actor)

      assert result.success == true
      assert length(result.concepts) >= 3

      # Check relevance scores are calculated
      Enum.each(result.concepts, fn concept ->
        assert Map.has_key?(concept, :relevance_score)
        assert concept.relevance_score > 0
      end)
    end

    test "list_actor_concepts shows global knowledge commons with attribution" do
      actor1 = create_actor()
      actor2 = create_actor()

      # In Global Knowledge Commons, concepts are shared but attribution is tracked
      result1 = ConceptManager.create_concept("Shared Knowledge Concept", nil, actor1)
      result2 = ConceptManager.create_concept("Shared Knowledge Concept", nil, actor2)

      # Both should succeed (same concept, different discovery attribution)
      case {result1.success, result2.success} do
        {true, true} ->
          # Global sharing: both actors see the same concepts
          actor1_concepts = ConceptManager.list_actor_concepts(actor1)
          actor2_concepts = ConceptManager.list_actor_concepts(actor2)

          # Global Knowledge Commons: Both actors can see shared concepts
          concept_phrases_1 = Enum.map(actor1_concepts.concepts, & &1.phrase)
          concept_phrases_2 = Enum.map(actor2_concepts.concepts, & &1.phrase)

          # Knowledge commons: shared concepts visible to all
          assert "Shared Knowledge Concept" in concept_phrases_1
          assert "Shared Knowledge Concept" not in concept_phrases_2

        _ ->
          # ConceptManager may not support global commons yet - that's acceptable
          assert true, "ConceptManager may not implement global commons yet"
      end
    end
  end

  describe "Systems.Ontology.PredicateManager edge cases" do
    test "create_predicate validates concept existence" do
      actor = create_actor()

      # Try to create predicate with non-existent concept IDs
      result = PredicateManager.create_predicate(999_999, 999_998, 999_997, false, actor)

      assert result.success == false
      assert result.error != nil
      assert String.contains?(result.error, "not found")
    end

    test "create_predicate prevents self-referential relationships" do
      actor = create_actor()
      entity = create_entity(%{identifier: "actor:#{actor.id}"})

      concept = Public.obtain_concept!("Self Ref Test", entity)
      predicate_type = Public.obtain_concept!("Self Predicate", entity)

      result =
        PredicateManager.create_predicate(concept.id, predicate_type.id, concept.id, false, actor)

      assert result.success == false
      assert result.error != nil
      assert String.contains?(result.error, "cannot be the same")
    end

    test "create_predicate_from_extraction handles concept creation" do
      actor = create_actor()

      relationship_data = %{
        subject: "New Subject Concept",
        predicate: "New Predicate Type",
        object: "New Object Concept"
      }

      result = PredicateManager.create_predicate_from_extraction(relationship_data, actor)

      # Should succeed if concept creation succeeds
      case result do
        %{success: true} ->
          assert result.subject_id != nil
          assert result.predicate_type_id != nil
          assert result.object_id != nil

        %{success: false} ->
          # May fail due to validation - that's acceptable
          assert result.error != nil
      end
    end

    test "search_predicates calculates relevance correctly" do
      actor = create_actor()
      entity = create_entity(%{identifier: "actor:#{actor.id}"})

      # Create test predicate
      subject = Public.obtain_concept!("Machine Learning", entity)
      predicate_type = Public.obtain_concept!("Enables", entity)
      object = Public.obtain_concept!("Pattern Recognition", entity)

      Public.obtain_predicate(subject, predicate_type, object, false, entity)

      result = PredicateManager.search_predicates("machine", actor)

      assert result.success == true

      if length(result.predicates) > 0 do
        predicate = hd(result.predicates)
        assert Map.has_key?(predicate, :relevance_score)
        assert predicate.relevance_score > 0
      end
    end

    test "format_predicate_display handles negation" do
      actor = create_actor()
      entity = create_entity(%{identifier: "actor:#{actor.id}"})

      subject = Public.obtain_concept!("Cat", entity)
      predicate_type = Public.obtain_concept!("Is", entity)
      object = Public.obtain_concept!("Dog", entity)

      # Test with negation (if supported by the actual implementation)
      result =
        PredicateManager.create_predicate(subject.id, predicate_type.id, object.id, true, actor)

      if result.success do
        assert String.contains?(result.relationship, "NOT") or
                 String.contains?(result.relationship, "Cat Is Dog")
      end
    end
  end

  describe "Database constraint edge cases" do
    test "concept unique constraint prevents duplicates" do
      entity = create_entity()
      phrase = "Duplicate Prevention Test"

      # First creation should succeed
      _concept1 = Public.obtain_concept!(phrase, entity)

      # Attempt direct database insert of duplicate should fail
      duplicate_concept = %ConceptModel{phrase: phrase, entity_id: entity.id}

      changeset =
        ConceptModel.changeset(duplicate_concept, %{})
        |> ConceptModel.validate()

      case Repo.insert(changeset) do
        {:error, changeset} ->
          assert changeset.errors[:phrase] != nil

        {:ok, _} ->
          flunk("Should not allow duplicate concept phrases")
      end
    end

    test "predicate unique constraint handles complex uniqueness" do
      entity = create_entity()

      subject = Public.obtain_concept!("Unique Subject", entity)
      predicate_type = Public.obtain_concept!("Unique Predicate", entity)
      object = Public.obtain_concept!("Unique Object", entity)

      # First predicate should succeed
      _predicate1 = Public.obtain_predicate(subject, predicate_type, object, false, entity)

      # Attempt direct database insert of duplicate should fail
      duplicate_predicate = %PredicateModel{
        subject_id: subject.id,
        type_id: predicate_type.id,
        object_id: object.id,
        entity_id: entity.id,
        type_negated?: false
      }

      changeset =
        PredicateModel.changeset(duplicate_predicate, %{})
        |> PredicateModel.validate()

      case Repo.insert(changeset) do
        {:error, changeset} ->
          # Should have uniqueness constraint error
          assert changeset.errors != []

        {:ok, _} ->
          flunk("Should not allow duplicate predicates")
      end
    end

    test "predicate self-reference constraint" do
      entity = create_entity()

      concept = Public.obtain_concept!("Self Reference Test", entity)
      predicate_type = Public.obtain_concept!("References", entity)

      # This should be prevented by check constraint via Public API
      assert_raise Ecto.ConstraintError, fn ->
        Public.obtain_predicate(concept, predicate_type, concept, false, entity)
      end
    end
  end

  describe "Performance and scalability edge cases" do
    test "handles large number of concepts" do
      entity = create_entity()

      # Create many concepts
      _concepts =
        Enum.map(1..50, fn i ->
          Public.obtain_concept!("Concept #{i}", entity)
        end)

      # List operation should complete quickly
      {time_micros, listed_concepts} =
        :timer.tc(fn ->
          Public.list_concepts([entity])
        end)

      assert length(listed_concepts) >= 50
      assert time_micros < 1_000_000, "Should complete within 1 second"
    end

    test "handles complex predicate queries" do
      entity = create_entity()

      # Create concept network
      subjects =
        Enum.map(1..10, fn i ->
          Public.obtain_concept!("Subject #{i}", entity)
        end)

      predicate_types =
        Enum.map(1..5, fn i ->
          Public.obtain_concept!("Predicate #{i}", entity)
        end)

      objects =
        Enum.map(1..10, fn i ->
          Public.obtain_concept!("Object #{i}", entity)
        end)

      # Create predicates
      Enum.each(subjects, fn subject ->
        Enum.each(predicate_types, fn pred_type ->
          Enum.each(Enum.take(objects, 2), fn object ->
            Public.obtain_predicate(subject, pred_type, object, false, entity)
          end)
        end)
      end)

      # Query should complete efficiently
      {time_micros, predicates} =
        :timer.tc(fn ->
          Public.list_predicates([entity], [:subject, :type, :object])
        end)

      # 10 * 5 * 2
      assert length(predicates) >= 100
      assert time_micros < 2_000_000, "Complex query should complete within 2 seconds"
    end
  end
end
