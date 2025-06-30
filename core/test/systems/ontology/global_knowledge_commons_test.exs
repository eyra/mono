defmodule Systems.Ontology.GlobalKnowledgeCommonsTest do
  @moduledoc """
  Critical tests for Global Knowledge Commons architecture changes.
  
  Tests focus on:
  - Global predicate uniqueness without entity isolation
  - Attribution preservation during schema migration
  - Concurrent predicate creation with global sharing
  - Backward compatibility with existing predicates
  - Performance impact of global predicate sharing
  """
  
  use Core.DataCase

  alias Systems.Ontology.{Public, PredicateModel}
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

  defp create_concept(phrase, entity) do
    Public.obtain_concept!(phrase, entity)
  end

  describe "Global Predicate Uniqueness" do
    test "multiple entities creating same predicate returns same ID" do
      entity1 = create_entity()
      entity2 = create_entity()
      entity3 = create_entity()
      
      # Create concepts that will be shared globally
      subject = create_concept("Machine Learning", entity1)
      predicate_type = create_concept("enables", entity1)
      object = create_concept("Pattern Recognition", entity1)
      
      # Multiple entities create the same logical predicate
      predicate1 = Public.obtain_predicate(subject, predicate_type, object, entity1)
      predicate2 = Public.obtain_predicate(subject, predicate_type, object, entity2)
      predicate3 = Public.obtain_predicate(subject, predicate_type, object, entity3)
      
      # Global Knowledge Commons: Same predicate ID returned
      assert predicate1.id == predicate2.id
      assert predicate1.id == predicate3.id
      
      # Attribution: First entity gets discovery credit
      assert predicate1.entity_id == entity1.id
      assert predicate2.entity_id == entity1.id  # Same predicate, same attribution
      assert predicate3.entity_id == entity1.id
    end
    
    test "predicate attribution preserved with global sharing" do
      entity1 = create_entity()
      entity2 = create_entity()
      
      subject = create_concept("Artificial Intelligence", entity1)
      predicate_type = create_concept("subsumes", entity1)
      object = create_concept("Machine Learning", entity1)
      
      # Entity 1 creates first
      predicate1 = Public.obtain_predicate(subject, predicate_type, object, entity1)
      original_created_at = predicate1.inserted_at
      
      # Wait a tiny bit to ensure different timestamp if created
      :timer.sleep(10)
      
      # Entity 2 tries to create same predicate
      predicate2 = Public.obtain_predicate(subject, predicate_type, object, entity2)
      
      # Same predicate returned
      assert predicate1.id == predicate2.id
      
      # Attribution and timing preserved from first creation
      assert predicate2.entity_id == entity1.id
      assert predicate2.inserted_at == original_created_at
    end
    
    test "negated predicates are distinct from positive predicates" do
      entity = create_entity()
      
      subject = create_concept("Cat", entity)
      predicate_type = create_concept("is_a", entity)
      object = create_concept("Dog", entity)
      
      # Create positive predicate
      positive_predicate = Public.obtain_predicate(subject, predicate_type, object, entity)
      
      # Create negated predicate
      {:ok, negated_predicate} = Public.insert_predicate(subject, predicate_type, object, entity, type_negated?: true)
      
      # Should be different predicates
      assert positive_predicate.id != negated_predicate.id
      assert positive_predicate.type_negated? == false
      assert negated_predicate.type_negated? == true
    end
  end

  describe "Concurrent Global Predicate Creation" do
    test "concurrent predicate creation with same relationship" do
      entity1 = create_entity()
      entity2 = create_entity()
      entity3 = create_entity()
      
      subject = create_concept("Deep Learning", entity1)
      predicate_type = create_concept("improves", entity1)
      object = create_concept("Image Recognition", entity1)
      
      # Concurrent predicate creation
      tasks = [
        Task.async(fn -> Public.obtain_predicate(subject, predicate_type, object, entity1) end),
        Task.async(fn -> Public.obtain_predicate(subject, predicate_type, object, entity2) end),
        Task.async(fn -> Public.obtain_predicate(subject, predicate_type, object, entity3) end)
      ]
      
      predicates = Enum.map(tasks, &Task.await(&1, 5000))
      
      # All should return same predicate ID (global sharing)
      predicate_ids = Enum.map(predicates, & &1.id) |> Enum.uniq()
      assert length(predicate_ids) == 1, "All concurrent calls should return same predicate ID"
      
      # All should have same attribution (first entity wins)
      entity_ids = Enum.map(predicates, & &1.entity_id) |> Enum.uniq()
      assert length(entity_ids) == 1, "All predicates should have same attribution"
    end
  end

  describe "Global Predicate Query Performance" do
    test "listing predicates with global sharing scales efficiently" do
      entity1 = create_entity()
      
      # Create test concepts
      subjects = Enum.map(1..10, fn i ->
        create_concept("Subject #{i}", entity1)
      end)
      
      predicate_types = Enum.map(1..3, fn i ->
        create_concept("Predicate Type #{i}", entity1)
      end)
      
      objects = Enum.map(1..10, fn i ->
        create_concept("Object #{i}", entity1)
      end)
      
      # Create predicates from entity1
      Enum.each(subjects, fn subject ->
        Enum.each(Enum.take(predicate_types, 2), fn pred_type ->
          Enum.each(Enum.take(objects, 2), fn object ->
            Public.obtain_predicate(subject, pred_type, object, entity1)
          end)
        end)
      end)
      
      # Query performance should be reasonable
      {time_micros, entity1_predicates} = :timer.tc(fn ->
        Public.list_predicates([entity1], [:subject, :type, :object])
      end)
      
      # Should complete queries efficiently
      assert time_micros < 2_000_000, "Query should complete within 2 seconds"
      assert length(entity1_predicates) > 0
    end
  end

  describe "Global Predicate Constraint Handling" do
    test "self-referential predicate constraints still work globally" do
      entity1 = create_entity()
      entity2 = create_entity()
      
      concept = create_concept("Self Reference Test", entity1)
      predicate_type = create_concept("references_itself", entity1)
      
      # Both entities should get same constraint violation
      assert_raise Ecto.ConstraintError, fn ->
        Public.obtain_predicate(concept, predicate_type, concept, entity1)
      end
      
      assert_raise Ecto.ConstraintError, fn ->
        Public.obtain_predicate(concept, predicate_type, concept, entity2)
      end
    end
    
    test "global predicate uniqueness constraint violations" do
      entity = create_entity()
      
      subject = create_concept("Constraint Test Subject", entity)
      predicate_type = create_concept("Constraint Test Type", entity)
      object = create_concept("Constraint Test Object", entity)
      
      # First predicate should succeed
      predicate1 = Public.obtain_predicate(subject, predicate_type, object, entity)
      assert predicate1.id != nil
      
      # Direct database insert of duplicate should fail due to global uniqueness
      duplicate_predicate = %PredicateModel{
        subject_id: subject.id,
        type_id: predicate_type.id,
        object_id: object.id,
        entity_id: entity.id,
        type_negated?: false
      }
      
      changeset = PredicateModel.changeset(duplicate_predicate, %{})
      |> PredicateModel.validate()
      
      case Repo.insert(changeset) do
        {:error, changeset} ->
          # Should have uniqueness constraint error
          assert changeset.errors != []
        {:ok, _} ->
          flunk("Should not allow duplicate predicates even with global sharing")
      end
    end
  end

  describe "Backward Compatibility" do
    test "existing predicates work with global sharing model" do
      entity = create_entity()
      
      # Create predicate using current API
      subject = create_concept("Legacy Subject", entity)
      predicate_type = create_concept("Legacy Predicate", entity)
      object = create_concept("Legacy Object", entity)
      
      predicate = Public.obtain_predicate(subject, predicate_type, object, entity)
      
      # Verify it has expected structure for global sharing
      assert predicate.subject_id == subject.id
      assert predicate.type_id == predicate_type.id
      assert predicate.object_id == object.id
      assert predicate.entity_id == entity.id
      assert predicate.type_negated? == false
      
      # Verify it can be retrieved
      retrieved = Public.get_predicate({subject, predicate_type, object, false})
      assert retrieved.id == predicate.id
    end
  end

  describe "Global Knowledge Commons Edge Cases" do
    test "massive concurrent predicate creation stress test" do
      entity = create_entity()
      
      # Single relationship that many entities try to create
      subject = create_concept("Stress Test Subject", entity)
      predicate_type = create_concept("Stress Test Predicate", entity)
      object = create_concept("Stress Test Object", entity)
      
      # Simulate many concurrent attempts to create same predicate
      task_count = 10
      tasks = Enum.map(1..task_count, fn _i ->
        # Create different entities for each task
        task_entity = create_entity()
        Task.async(fn ->
          Public.obtain_predicate(subject, predicate_type, object, task_entity)
        end)
      end)
      
      predicates = Enum.map(tasks, &Task.await(&1, 10000))
      
      # All should return same predicate ID
      predicate_ids = Enum.map(predicates, & &1.id) |> Enum.uniq()
      assert length(predicate_ids) == 1, "All concurrent attempts should return same predicate"
      
      # Attribution should be consistent (first entity wins)
      entity_ids = Enum.map(predicates, & &1.entity_id) |> Enum.uniq()
      assert length(entity_ids) == 1, "Attribution should be consistent across all results"
    end
    
    test "global predicate sharing basic verification" do
      entity1 = create_entity()
      entity2 = create_entity()
      
      # Create simple relationship
      subject = create_concept("AI", entity1)
      predicate_type = create_concept("subsumes", entity1)
      object = create_concept("ML", entity1)
      
      # Both entities create same relationship
      pred1 = Public.obtain_predicate(subject, predicate_type, object, entity1)
      pred2 = Public.obtain_predicate(subject, predicate_type, object, entity2)
      
      # Should be same predicate due to global sharing
      assert pred1.id == pred2.id
      
      # Entity1 should see predicates it discovered
      entity1_predicates = Public.list_predicates([entity1], [])
      assert length(entity1_predicates) > 0
    end
  end
end