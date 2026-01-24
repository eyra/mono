defmodule Frameworks.UserState.SchemaRegistryTest do
  use ExUnit.Case, async: true

  alias Frameworks.UserState.SchemaRegistry
  alias Frameworks.UserState.Schemas.V1
  alias Frameworks.UserState.Schemas.V2

  describe "ladder/0" do
    test "returns ladder with V2 first, V1 second" do
      ladder = SchemaRegistry.ladder()

      assert [{V2, nil}, {V1, _migrator}] = ladder
    end
  end

  describe "current_schema/0" do
    test "returns V2 as current schema" do
      assert SchemaRegistry.current_schema() == V2
    end
  end

  describe "parse/2 with V2 data" do
    test "parses valid V2 assignment data" do
      flat_state = %{
        "next://user-10@localhost/assignment/5/crew/3/task" => "4"
      }

      assert {:ok, validated} = SchemaRegistry.parse(flat_state, 10)
      assert %V2{} = validated
      assert [assignment] = validated.assignments
      assert assignment.id == 5
      assert [crew] = assignment.crews
      assert crew.id == 3
      assert crew.task == 4
    end

    test "parses valid V2 manual data" do
      flat_state = %{
        "next://user-10@localhost/manual/5/chapter" => "2",
        "next://user-10@localhost/manual/5/page" => "10"
      }

      assert {:ok, validated} = SchemaRegistry.parse(flat_state, 10)
      assert %V2{} = validated
      assert [manual] = validated.manuals
      assert manual.id == 5
      assert manual.chapter == 2
      assert manual.page == 10
    end

    test "parses multiple assignments and crews" do
      flat_state = %{
        "next://user-10@localhost/assignment/5/crew/3/task" => "4",
        "next://user-10@localhost/assignment/5/crew/7/task" => "8",
        "next://user-10@localhost/assignment/10/crew/1/task" => "2"
      }

      assert {:ok, validated} = SchemaRegistry.parse(flat_state, 10)
      assert length(validated.assignments) == 2
    end

    test "filters by user_id" do
      flat_state = %{
        "next://user-10@localhost/assignment/5/crew/3/task" => "4",
        "next://user-20@localhost/assignment/5/crew/3/task" => "99"
      }

      assert {:ok, validated} = SchemaRegistry.parse(flat_state, 10)
      [assignment] = validated.assignments
      [crew] = assignment.crews
      assert crew.task == 4
    end

    test "returns empty state for empty input" do
      assert {:ok, validated} = SchemaRegistry.parse(%{}, 10)
      assert validated.assignments == []
      assert validated.manuals == []
    end
  end

  describe "parse/2 with V1 legacy data" do
    test "migrates V1 assignment with legacy value to V2" do
      flat_state = %{
        "next://user-10@localhost/assignment/5" => "103"
      }

      assert {:ok, validated} = SchemaRegistry.parse(flat_state, 10)
      # V1 data is migrated to V2, legacy values are dropped
      assert %V2{} = validated
    end

    test "migrates V1 with mixed legacy and V2 data" do
      flat_state = %{
        "next://user-10@localhost/assignment/5" => "103",
        "next://user-10@localhost/assignment/5/crew/3/task" => "4"
      }

      assert {:ok, validated} = SchemaRegistry.parse(flat_state, 10)
      assert %V2{} = validated
      # The legacy value is dropped, nested crew data is preserved
      [assignment] = validated.assignments
      [crew] = assignment.crews
      assert crew.task == 4
    end
  end

  describe "validate_and_migrate/1" do
    test "validates V2 attrs without migration" do
      attrs = %{
        assignments: [%{id: 5, crews: [%{id: 3, task: 4}]}],
        manuals: []
      }

      assert {:ok, validated} = SchemaRegistry.validate_and_migrate(attrs)
      assert %V2{} = validated
    end

    test "migrates V1 attrs to V2" do
      attrs = %{
        assignments: [%{id: 5, value: 103, crews: []}],
        manuals: []
      }

      assert {:ok, validated} = SchemaRegistry.validate_and_migrate(attrs)
      assert %V2{} = validated
      # V1 value field is dropped in migration
    end

    test "returns error for completely invalid data" do
      attrs = %{
        assignments: "not a list",
        manuals: []
      }

      assert {:error, :invalid_user_state} = SchemaRegistry.validate_and_migrate(attrs)
    end
  end
end
