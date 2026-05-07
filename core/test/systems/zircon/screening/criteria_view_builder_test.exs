defmodule Systems.Zircon.Screening.CriteriaViewBuilderTest do
  use Core.DataCase
  alias Systems.Zircon.Screening.CriteriaViewBuilder

  setup do
    # Create required authentication entities
    actor = Core.Authentication.obtain_actor!(:system, "Zircon")
    entity = Core.Authentication.obtain_entity!(actor)

    %{actor: actor, entity: entity}
  end

  describe "view_model/2" do
    test "creates view model with empty annotations", %{entity: _entity} do
      tool = %{annotations: []}
      assigns = %{}

      result = CriteriaViewBuilder.view_model(tool, assigns)

      assert Map.has_key?(result, :dimension_list)
      assert Map.has_key?(result, :library_items)
      assert Map.has_key?(result, :criteria_list)
      assert result.criteria_list == []
      assert is_list(result.dimension_list)
      assert is_list(result.library_items)
    end

    test "filters annotations by parameter type", %{entity: _entity} do
      # Create annotations with different types
      parameter_type = %{phrase: Systems.Annotation.Pattern.Parameter.type_phrase()}
      other_type = %{phrase: "other_type"}

      annotations = [
        %{type: parameter_type, inserted_at: ~N[2024-01-01 10:00:00], id: 1},
        %{type: other_type, inserted_at: ~N[2024-01-01 11:00:00], id: 2},
        %{type: parameter_type, inserted_at: ~N[2024-01-01 12:00:00], id: 3}
      ]

      tool = %{annotations: annotations}
      assigns = %{}

      result = CriteriaViewBuilder.view_model(tool, assigns)

      # Should only include parameter type annotations
      assert length(result.criteria_list) == 2

      assert Enum.all?(result.criteria_list, fn ann ->
               ann.type.phrase == Systems.Annotation.Pattern.Parameter.type_phrase()
             end)
    end

    test "sorts criteria by insertion time ascending", %{entity: _entity} do
      parameter_type = %{phrase: Systems.Annotation.Pattern.Parameter.type_phrase()}

      annotations = [
        %{type: parameter_type, inserted_at: ~N[2024-01-03 10:00:00], id: 3},
        %{type: parameter_type, inserted_at: ~N[2024-01-01 10:00:00], id: 1},
        %{type: parameter_type, inserted_at: ~N[2024-01-02 10:00:00], id: 2}
      ]

      tool = %{annotations: annotations}
      assigns = %{}

      result = CriteriaViewBuilder.view_model(tool, assigns)

      # Should be sorted by inserted_at ascending
      assert [first, second, third] = result.criteria_list
      assert first.id == 1
      assert second.id == 2
      assert third.id == 3
    end

    test "creates library items from dimensions", %{entity: _entity} do
      tool = %{annotations: []}
      assigns = %{}

      result = CriteriaViewBuilder.view_model(tool, assigns)

      # Library items should be created from research dimensions
      assert is_list(result.library_items)

      # Each library item should have the expected structure
      Enum.each(result.library_items, fn item ->
        assert %Frameworks.Builder.LibraryItemModel{} = item
        assert item.id != nil
        assert item.type == "Research Dimension"
        assert item.title != nil
        assert is_list(item.tags)
      end)
    end

    test "sorts library items by title", %{entity: _entity} do
      tool = %{annotations: []}
      assigns = %{}

      result = CriteriaViewBuilder.view_model(tool, assigns)

      if length(result.library_items) > 1 do
        titles = Enum.map(result.library_items, & &1.title)
        sorted_titles = Enum.sort(titles)
        assert titles == sorted_titles
      end
    end

    test "includes dimension list from research dimensions", %{entity: _entity} do
      tool = %{annotations: []}
      assigns = %{}

      result = CriteriaViewBuilder.view_model(tool, assigns)

      assert is_list(result.dimension_list)
      # The dimension list should match what's returned by list_research_dimensions()
      expected_dimensions = Systems.Zircon.Private.list_research_dimensions()
      assert length(result.dimension_list) == length(expected_dimensions)
    end
  end

  describe "library item creation" do
    test "creates library items with correct structure", %{entity: _entity} do
      tool = %{annotations: []}
      assigns = %{}

      result = CriteriaViewBuilder.view_model(tool, assigns)

      # Check that library items have the correct fields
      Enum.each(result.library_items, fn item ->
        assert Map.has_key?(item, :id)
        assert Map.has_key?(item, :type)
        assert Map.has_key?(item, :title)
        assert Map.has_key?(item, :tags)
        assert Map.has_key?(item, :description)

        # Type should always be "Research Dimension"
        assert item.type == "Research Dimension"

        # ID and title should match the dimension phrase
        assert item.id == item.title
      end)
    end

    test "handles dimensions without frameworks", %{entity: _entity} do
      # This test ensures the system doesn't crash when dimensions have no associated frameworks
      tool = %{annotations: []}
      assigns = %{}

      # Should not raise an error even if some dimensions have no frameworks
      result = CriteriaViewBuilder.view_model(tool, assigns)

      assert is_list(result.library_items)

      # Tags can be empty lists
      Enum.each(result.library_items, fn item ->
        # Can be empty, but must be a list
        assert is_list(item.tags)
      end)
    end
  end

  describe "integration with annotations" do
    test "processes real annotation data correctly", %{entity: _entity} do
      parameter_type = %{phrase: Systems.Annotation.Pattern.Parameter.type_phrase()}

      # Create more realistic annotation data
      annotations = [
        %{
          id: 1,
          type: parameter_type,
          inserted_at: ~N[2024-01-01 10:00:00],
          value: "inclusion_criteria_1",
          label: "Age > 18"
        },
        %{
          id: 2,
          type: parameter_type,
          inserted_at: ~N[2024-01-01 11:00:00],
          value: "exclusion_criteria_1",
          label: "Previous diagnosis"
        }
      ]

      tool = %{annotations: annotations}
      assigns = %{}

      result = CriteriaViewBuilder.view_model(tool, assigns)

      assert length(result.criteria_list) == 2

      # Verify the annotations are preserved with their data
      [first, second] = result.criteria_list
      assert first.value == "inclusion_criteria_1"
      assert second.value == "exclusion_criteria_1"
    end

    test "handles mixed annotation types correctly", %{entity: _entity} do
      parameter_type = %{phrase: Systems.Annotation.Pattern.Parameter.type_phrase()}
      tag_type = %{phrase: "tag"}
      category_type = %{phrase: "category"}

      annotations = [
        %{type: parameter_type, inserted_at: ~N[2024-01-01 10:00:00], id: 1},
        %{type: tag_type, inserted_at: ~N[2024-01-01 11:00:00], id: 2},
        %{type: category_type, inserted_at: ~N[2024-01-01 12:00:00], id: 3},
        %{type: parameter_type, inserted_at: ~N[2024-01-01 13:00:00], id: 4}
      ]

      tool = %{annotations: annotations}
      assigns = %{}

      result = CriteriaViewBuilder.view_model(tool, assigns)

      # Should only include parameter type annotations
      assert length(result.criteria_list) == 2
      assert Enum.map(result.criteria_list, & &1.id) == [1, 4]
    end
  end

  describe "edge cases" do
    test "handles nil annotations gracefully", %{entity: _entity} do
      tool = %{annotations: nil}
      assigns = %{}

      # Should raise an error when annotations is nil (not a list)
      assert_raise Protocol.UndefinedError, fn ->
        CriteriaViewBuilder.view_model(tool, assigns)
      end
    end

    test "handles empty assigns", %{entity: _entity} do
      tool = %{annotations: []}
      assigns = nil

      # Should work with nil assigns
      result = CriteriaViewBuilder.view_model(tool, assigns)

      assert Map.has_key?(result, :dimension_list)
      assert Map.has_key?(result, :library_items)
      assert Map.has_key?(result, :criteria_list)
    end

    test "preserves all annotation fields", %{entity: _entity} do
      parameter_type = %{phrase: Systems.Annotation.Pattern.Parameter.type_phrase()}

      annotation = %{
        id: 123,
        type: parameter_type,
        inserted_at: ~N[2024-01-01 10:00:00],
        value: "test_value",
        label: "Test Label",
        description: "Test Description",
        custom_field: "Custom Data"
      }

      tool = %{annotations: [annotation]}
      assigns = %{}

      result = CriteriaViewBuilder.view_model(tool, assigns)

      # The annotation should be preserved with all its fields
      assert [criteria] = result.criteria_list
      assert criteria.id == 123
      assert criteria.value == "test_value"
      assert criteria.label == "Test Label"
      assert criteria.description == "Test Description"
      assert criteria.custom_field == "Custom Data"
    end
  end
end
