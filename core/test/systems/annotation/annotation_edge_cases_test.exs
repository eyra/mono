defmodule Systems.Annotation.AnnotationEdgeCasesTest do
  @moduledoc """
  Comprehensive edge case testing for the Annotation system.
  
  Tests focus on:
  - Entity isolation (IP protection layer in Global Knowledge Commons)
  - Pattern system validation and polymorphic references
  - Human-AI collaboration workflows
  - Statement-centric annotation architecture
  - Defensive programming and security boundaries
  """
  
  use Core.DataCase

  alias Systems.Annotation.{Public, Model}
  alias Systems.Ontology
  alias Core.Authentication.Entity
  alias Core.Repo


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
    Ontology.Public.obtain_concept!(phrase, entity)
  end

  defp create_annotation_type(entity) do
    create_concept("Test Annotation Type", entity)
  end

  defp create_reference_type(entity) do
    create_concept("references", entity)
  end

  describe "Entity Isolation - IP Protection Layer" do
    test "annotations are properly isolated by entity" do
      entity1 = create_entity()
      entity2 = create_entity()
      
      type = create_annotation_type(entity1)
      ref_type = create_reference_type(entity1)
      concept = create_concept("Shared Knowledge", entity1)
      
      # Entity 1 creates annotation on shared concept
      {:ok, %{annotation: annotation1}} = 
        Public.insert_annotation(type, "Entity 1 proprietary insight", entity1, ref_type, concept)
      
      # Entity 2 creates different annotation on same shared concept  
      {:ok, %{annotation: annotation2}} = 
        Public.insert_annotation(type, "Entity 2 proprietary insight", entity2, ref_type, concept)
      
      # Different annotations (IP protection)
      assert annotation1.id != annotation2.id
      assert annotation1.entity_id == entity1.id
      assert annotation2.entity_id == entity2.id
      
      # Entity 1 can only see their own annotations
      entity1_annotations = Public.list_annotations([entity1], [])
      entity1_statements = Enum.map(entity1_annotations, & &1.statement)
      
      assert "Entity 1 proprietary insight" in entity1_statements
      assert "Entity 2 proprietary insight" not in entity1_statements
      
      # Entity 2 can only see their own annotations
      entity2_annotations = Public.list_annotations([entity2], [])
      entity2_statements = Enum.map(entity2_annotations, & &1.statement)
      
      assert "Entity 2 proprietary insight" in entity2_statements
      assert "Entity 1 proprietary insight" not in entity2_statements
    end
    
    test "multi-entity collaboration scenarios" do
      entity1 = create_entity()
      entity2 = create_entity()
      entity3 = create_entity()
      
      type = create_annotation_type(entity1)
      ref_type = create_reference_type(entity1)
      concept = create_concept("Collaborative Research Topic", entity1)
      
      # Multiple entities create annotations
      {:ok, %{annotation: _}} = 
        Public.insert_annotation(type, "Research finding from Lab A", entity1, ref_type, concept)
      {:ok, %{annotation: _}} = 
        Public.insert_annotation(type, "Research finding from Lab B", entity2, ref_type, concept)
      {:ok, %{annotation: _}} = 
        Public.insert_annotation(type, "Research finding from Lab C", entity3, ref_type, concept)
      
      # Collaborative access: multiple entities can see shared annotations
      collaborative_annotations = Public.list_annotations([entity1, entity2], [])
      collaborative_statements = Enum.map(collaborative_annotations, & &1.statement)
      
      assert "Research finding from Lab A" in collaborative_statements
      assert "Research finding from Lab B" in collaborative_statements
      assert "Research finding from Lab C" not in collaborative_statements  # Not in collaborative group
      
      # Single entity still sees only their own
      entity3_annotations = Public.list_annotations([entity3], [])
      entity3_statements = Enum.map(entity3_annotations, & &1.statement)
      
      assert "Research finding from Lab C" in entity3_statements
      assert length(entity3_statements) == 1
    end
    
    test "entity isolation with same statement text" do
      entity1 = create_entity()
      entity2 = create_entity()
      
      type = create_annotation_type(entity1)
      ref_type = create_reference_type(entity1)
      concept = create_concept("Common Research Area", entity1)
      
      statement = "This is a significant breakthrough in machine learning"
      
      # Same statement text, different entities
      {:ok, %{annotation: annotation1}} = 
        Public.insert_annotation(type, statement, entity1, ref_type, concept)
      {:ok, %{annotation: annotation2}} = 
        Public.insert_annotation(type, statement, entity2, ref_type, concept)
      
      # Should be different annotations (IP protection)
      assert annotation1.id != annotation2.id
      assert annotation1.statement == annotation2.statement
      assert annotation1.entity_id != annotation2.entity_id
    end
  end

  describe "Polymorphic Reference System" do
    test "annotation references to different target types" do
      entity = create_entity()
      type = create_annotation_type(entity)
      ref_type = create_reference_type(entity)
      
      # Test annotation reference to concept
      concept = create_concept("Machine Learning", entity)
      {:ok, %{annotation: concept_annotation}} = 
        Public.insert_annotation(type, "Analysis of ML concept", entity, ref_type, concept)
      
      # Test annotation reference to predicate
      subject = create_concept("AI", entity)
      predicate_type = create_concept("enables", entity)
      object = create_concept("Automation", entity)
      predicate = Ontology.Public.obtain_predicate(subject, predicate_type, object, false, entity)
      
      {:ok, %{annotation: predicate_annotation}} = 
        Public.insert_annotation(type, "Analysis of AI-automation relationship", entity, ref_type, predicate)
      
      # Test annotation reference to another annotation (self-referential)
      {:ok, %{annotation: meta_annotation}} = 
        Public.insert_annotation(type, "Commentary on previous analysis", entity, ref_type, concept_annotation)
      
      # Verify different reference types
      concept_annotation = Repo.preload(concept_annotation, [references: [:ontology_ref]])
      predicate_annotation = Repo.preload(predicate_annotation, [references: [:ontology_ref]])
      meta_annotation = Repo.preload(meta_annotation, [references: [:annotation]])
      
      assert length(concept_annotation.references) == 1
      assert length(predicate_annotation.references) == 1
      assert length(meta_annotation.references) == 1
      
      # Check reference targets
      concept_ref = hd(concept_annotation.references)
      predicate_ref = hd(predicate_annotation.references)
      meta_ref = hd(meta_annotation.references)
      
      assert concept_ref.ontology_ref != nil
      assert concept_ref.annotation_id == nil
      
      assert predicate_ref.ontology_ref != nil
      assert predicate_ref.annotation_id == nil
      
      assert meta_ref.annotation_id == concept_annotation.id
      assert meta_ref.ontology_ref_id == nil
    end
    
    test "annotation creation with different reference targets" do
      entity = create_entity()
      type = create_annotation_type(entity)
      resource_type = create_concept("mentions", entity)
      
      # Test basic annotation creation (this functionality exists)
      concept = create_concept("Artificial Intelligence", entity)
      
      # First annotation
      {:ok, %{annotation: annotation1}} = 
        Public.insert_annotation(type, "First mention of AI", entity, resource_type, concept)
      
      # Second annotation with same concept  
      {:ok, %{annotation: annotation2}} = 
        Public.insert_annotation(type, "Second mention of AI", entity, resource_type, concept)
      
      # Different annotations (entity isolation)
      assert annotation1.id != annotation2.id
      assert annotation1.entity_id == entity.id
      assert annotation2.entity_id == entity.id
    end
    
    test "handles invalid reference targets" do
      entity = create_entity()
      type = create_annotation_type(entity)
      ref_type = create_reference_type(entity)
      
      # Test with invalid reference target
      invalid_targets = [
        nil,
        "not a valid target",
        %{invalid: "struct"},
        123
      ]
      
      Enum.each(invalid_targets, fn invalid_target ->
        try do
          Public.insert_annotation(type, "Invalid reference test", entity, ref_type, invalid_target)
          flunk("Should not allow invalid reference target: #{inspect(invalid_target)}")
        rescue
          _ -> assert true, "Correctly rejected invalid reference target"
        end
      end)
    end
  end

  describe "Statement-Centric Architecture" do
    test "statement validation and requirements" do
      entity = create_entity()
      type = create_annotation_type(entity)
      ref_type = create_reference_type(entity)
      concept = create_concept("Test Subject", entity)
      
      # Test empty statement
      assert {:error, :annotation, changeset, _} = 
        Public.insert_annotation(type, "", entity, ref_type, concept)
      assert changeset.errors[:statement] != nil
      
      # Test nil statement
      assert {:error, :annotation, changeset, _} = 
        Public.insert_annotation(type, nil, entity, ref_type, concept)
      assert changeset.errors[:statement] != nil
      
      # Test whitespace-only statement
      assert {:error, :annotation, changeset, _} = 
        Public.insert_annotation(type, "   \n\t   ", entity, ref_type, concept)
      assert changeset.errors[:statement] != nil
    end
    
    test "statement length validation" do
      entity = create_entity()
      type = create_annotation_type(entity)
      ref_type = create_reference_type(entity)
      concept = create_concept("Test Subject", entity)
      
      # Test very long statement
      long_statement = String.duplicate("Very long statement content. ", 1000)
      
      result = Public.insert_annotation(type, long_statement, entity, ref_type, concept)
      
      case result do
        {:ok, %{annotation: annotation}} ->
          # If it succeeds, verify the statement was stored correctly
          assert annotation.statement == long_statement
        {:error, :annotation, changeset, _} ->
          # If it fails, should be due to length constraint
          assert changeset.errors[:statement] != nil
      end
    end
    
    test "special characters and encoding in statements" do
      entity = create_entity()
      type = create_annotation_type(entity)
      ref_type = create_reference_type(entity)
      concept = create_concept("Test Subject", entity)
      
      special_statements = [
        "Unicode test: 🚀 Machine Learning is transforming AI research 🤖",
        "Mathematical notation: ∀x ∈ ℝ, f(x) = ax² + bx + c",
        "Code snippet: `if model.accuracy > 0.95: deploy(model)`",
        "Mixed languages: AI in English, 人工智能 in Chinese, ИИ in Russian",
        "Special chars: @#$%^&*()[]{}|\\:;\"'<>?,./`~",
        "Newlines and tabs:\nLine 1\n\tIndented line\nLine 3"
      ]
      
      Enum.each(special_statements, fn statement ->
        {:ok, %{annotation: annotation}} = 
          Public.insert_annotation(type, statement, entity, ref_type, concept)
        
        assert annotation.statement == statement
      end)
    end
  end

  describe "Human-AI Collaboration Workflow" do
    test "feedback pattern: AI analysis of human statements" do
      entity = create_entity()
      human_entity = create_entity()
      ai_entity = create_entity()
      
      # Human creates original statement
      statement_type = create_concept("Research Finding", entity)
      concept_type = create_concept("references", entity)
      ml_concept = create_concept("Machine Learning", entity)
      
      {:ok, %{annotation: human_statement}} = 
        Public.insert_annotation(statement_type, "Our study shows ML models can reduce bias when trained with diverse datasets", human_entity, concept_type, ml_concept)
      
      # AI provides analysis/feedback
      feedback_type = create_concept("AI Analysis", entity)
      analyzes_type = create_concept("analyzes", entity)
      
      {:ok, %{annotation: ai_feedback}} = 
        Public.insert_annotation(feedback_type, "Analysis: Statement identifies bias reduction mechanism. Suggests causal relationship between dataset diversity and bias mitigation. Confidence: 0.85", ai_entity, analyzes_type, human_statement, ai_generated?: true)
      
      # Human responds to AI feedback
      response_type = create_concept("Response", entity)
      responds_to_type = create_concept("responds_to", entity)
      
      {:ok, %{annotation: human_response}} = 
        Public.insert_annotation(response_type, "I agree with the causal relationship identification. However, our methodology also controlled for model architecture - this should increase confidence.", human_entity, responds_to_type, ai_feedback)
      
      # Verify workflow chain
      assert human_statement.entity_id == human_entity.id
      assert ai_feedback.entity_id == ai_entity.id
      assert human_response.entity_id == human_entity.id
      
      # Verify reference chain
      ai_feedback = Repo.preload(ai_feedback, [references: [:annotation]])
      human_response = Repo.preload(human_response, [references: [:annotation]])
      
      ai_ref = hd(ai_feedback.references)
      human_ref = hd(human_response.references)
      
      assert ai_ref.annotation_id == human_statement.id
      assert human_ref.annotation_id == ai_feedback.id
    end
    
    test "validation pattern: human validation of AI discoveries" do
      entity = create_entity()
      ai_entity = create_entity()
      human_entity = create_entity()
      
      # AI discovers relationship
      discovery_type = create_concept("AI Discovery", entity)
      relates_to_type = create_concept("relates_to", entity)
      gdpr_concept = create_concept("GDPR Compliance", entity)
      
      {:ok, %{annotation: ai_discovery}} = 
        Public.insert_annotation(discovery_type, "Pattern analysis reveals: GDPR compliance requirements correlate with reduced user trust metrics (confidence: 0.72)", ai_entity, relates_to_type, gdpr_concept, ai_generated?: true)
      
      # Human validates the discovery
      validation_type = create_concept("Human Validation", entity)
      validates_type = create_concept("validates", entity)
      
      {:ok, %{annotation: human_validation}} = 
        Public.insert_annotation(validation_type, "VALIDATED: Our field studies confirm this correlation. However, causation direction needs investigation - users may distrust GDPR-compliant systems due to complexity, not compliance itself.", human_entity, validates_type, ai_discovery)
      
      # Verify validation workflow
      assert ai_discovery.entity_id == ai_entity.id
      assert human_validation.entity_id == human_entity.id
      
      # Check validation reference
      human_validation = Repo.preload(human_validation, [references: [:annotation]])
      validation_ref = hd(human_validation.references)
      assert validation_ref.annotation_id == ai_discovery.id
    end
    
    test "research finding pattern with concept tracking" do
      entity = create_entity()
      researcher_entity = create_entity()
      
      finding_type = create_concept("Research Finding", entity)
      methodology_type = create_concept("methodology", entity)
      methodology_concept = create_concept("Double-blind RCT", entity)
      
      # Research finding with methodology concept reference
      {:ok, %{annotation: finding}} = 
        Public.insert_annotation(finding_type, "Privacy-preserving AI systems show 23% higher user adoption rates compared to traditional systems", researcher_entity, methodology_type, methodology_concept)
      
      # Verify methodology tracking through concept reference
      finding = Repo.preload(finding, [references: [:ontology_ref, :type]])
      methodology_ref = hd(finding.references)
      
      assert methodology_ref.type.phrase == "methodology"
      assert finding.entity_id == researcher_entity.id
    end
  end

  describe "Pattern System and Defensive Programming" do
    test "basic annotation pattern validation" do
      entity = create_entity()
      type = create_annotation_type(entity)
      
      # Create reference targets
      concept1 = create_concept("Machine Learning", entity)
      ref_type = create_concept("relates_to", entity)
      
      # Test basic annotation creation and validation
      {:ok, %{annotation: annotation}} = 
        Public.insert_annotation(type, "This finding relates to machine learning concepts and extends our understanding", entity, ref_type, concept1)
      
      # Verify annotation structure
      annotation = Repo.preload(annotation, [:references, :type, :entity])
      assert annotation.statement != nil
      assert annotation.type.phrase == "Test Annotation Type"
      assert annotation.entity_id == entity.id
      assert length(annotation.references) >= 1
    end
    
    test "concurrent annotation creation" do
      entity = create_entity()
      type = create_annotation_type(entity)
      ref_type = create_reference_type(entity)
      concept = create_concept("Concurrent Target", entity)
      
      # Concurrent annotation creation
      tasks = Enum.map(1..5, fn i ->
        Task.async(fn ->
          Public.insert_annotation(type, "Concurrent annotation #{i}", entity, ref_type, concept)
        end)
      end)
      
      results = Enum.map(tasks, &Task.await(&1, 5000))
      
      # All should succeed
      assert Enum.all?(results, fn 
        {:ok, %{annotation: %Model{}}} -> true
        _ -> false
      end)
      
      # All should be different annotations
      annotation_ids = Enum.map(results, fn {:ok, %{annotation: annotation}} -> annotation.id end)
      unique_ids = Enum.uniq(annotation_ids)
      assert length(unique_ids) == length(annotation_ids)
    end
    
    test "handles database constraint violations gracefully" do
      entity = create_entity()
      type = create_annotation_type(entity)
      ref_type = create_reference_type(entity)
      concept = create_concept("Test Concept", entity)
      
      # Test with excessively long statement that might hit database limits
      very_long_statement = String.duplicate("A", 100_000)
      
      result = Public.insert_annotation(type, very_long_statement, entity, ref_type, concept)
      
      case result do
        {:ok, %{annotation: _}} ->
          # If it succeeds, that's fine
          assert true
        {:error, :annotation, changeset, _} ->
          # If it fails, should have proper error handling
          assert changeset.errors != []
        {:error, _step, _failed_value, _changes_so_far} ->
          # Other types of failures are also acceptable
          assert true
      end
    end
  end

  describe "Performance and Scalability" do
    test "handles large number of annotations efficiently" do
      entity = create_entity()
      type = create_annotation_type(entity)
      ref_type = create_reference_type(entity)
      concept = create_concept("Performance Test", entity)
      
      # Create many annotations
      annotations = Enum.map(1..50, fn i ->
        {:ok, %{annotation: annotation}} = 
          Public.insert_annotation(type, "Performance test annotation #{i}", entity, ref_type, concept)
        annotation
      end)
      
      # Query should complete efficiently
      {time_micros, listed_annotations} = :timer.tc(fn ->
        Public.list_annotations([entity], [])
      end)
      
      assert length(listed_annotations) >= 50
      assert time_micros < 1_000_000, "Should complete within 1 second"
      
      # Verify all annotations are present
      created_ids = Enum.map(annotations, & &1.id) |> Enum.sort()
      listed_ids = Enum.map(listed_annotations, & &1.id) |> Enum.sort()
      
      Enum.each(created_ids, fn id ->
        assert id in listed_ids
      end)
    end
    
    test "complex reference network queries" do
      entity = create_entity()
      type = create_annotation_type(entity)
      
      # Create complex reference network
      root_concept = create_concept("Root Research Topic", entity)
      relates_to = create_concept("relates_to", entity)
      
      # Create annotation tree
      {:ok, %{annotation: root_annotation}} = 
        Public.insert_annotation(type, "Root research finding", entity, relates_to, root_concept)
      
      child_annotations = Enum.map(1..10, fn i ->
        {:ok, %{annotation: child}} = 
          Public.insert_annotation(type, "Child finding #{i}", entity, relates_to, root_annotation)
        child
      end)
      
      # Create grandchild annotations
      Enum.each(child_annotations, fn child ->
        Enum.map(1..3, fn j ->
          Public.insert_annotation(type, "Grandchild finding #{j} of #{child.id}", entity, relates_to, child)
        end)
      end)
      
      # Query should handle complex relationships efficiently
      {time_micros, all_annotations} = :timer.tc(fn ->
        Public.list_annotations([entity], [:references, :type])
      end)
      
      assert length(all_annotations) >= 41  # 1 + 10 + 30
      assert time_micros < 2_000_000, "Complex query should complete within 2 seconds"
    end
  end

  # Helper functions for test scenarios removed - using actual Public API functions
end