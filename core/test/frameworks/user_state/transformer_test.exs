defmodule Frameworks.UserState.TransformerTest do
  use ExUnit.Case, async: true

  alias Frameworks.UserState.Transformer

  describe "flat_to_nested/2" do
    test "transforms assignment crew task" do
      flat = %{
        "next://user-10@localhost/assignment/5/crew/3/task" => "4"
      }

      {:ok, attrs, conflicts} = Transformer.flat_to_nested(flat, 10)

      assert conflicts == []
      assert [assignment] = attrs.assignments
      assert assignment.id == 5
      assert [crew] = assignment.crews
      assert crew.id == 3
      assert crew.task == 4
    end

    test "transforms manual chapter and page" do
      flat = %{
        "next://user-10@localhost/manual/5/chapter" => "2",
        "next://user-10@localhost/manual/5/page" => "10"
      }

      {:ok, attrs, conflicts} = Transformer.flat_to_nested(flat, 10)

      assert conflicts == []
      assert [manual] = attrs.manuals
      assert manual.id == 5
      assert manual.chapter == 2
      assert manual.page == 10
    end

    test "handles multiple assignments" do
      flat = %{
        "next://user-10@localhost/assignment/5/crew/3/task" => "4",
        "next://user-10@localhost/assignment/10/crew/1/task" => "2"
      }

      {:ok, attrs, _} = Transformer.flat_to_nested(flat, 10)

      assert length(attrs.assignments) == 2
    end

    test "handles multiple crews in same assignment" do
      flat = %{
        "next://user-10@localhost/assignment/5/crew/3/task" => "4",
        "next://user-10@localhost/assignment/5/crew/7/task" => "8"
      }

      {:ok, attrs, _} = Transformer.flat_to_nested(flat, 10)

      assert [assignment] = attrs.assignments
      assert length(assignment.crews) == 2
    end

    test "handles V1 legacy assignment value" do
      flat = %{
        "next://user-10@localhost/assignment/5" => "103"
      }

      {:ok, attrs, _} = Transformer.flat_to_nested(flat, 10)

      assert [assignment] = attrs.assignments
      assert assignment.value == 103
    end

    test "filters by user_id" do
      flat = %{
        "next://user-10@localhost/assignment/5/crew/3/task" => "4",
        "next://user-20@localhost/assignment/5/crew/3/task" => "99"
      }

      {:ok, attrs, _} = Transformer.flat_to_nested(flat, 10)

      assert [assignment] = attrs.assignments
      [crew] = assignment.crews
      assert crew.task == 4
    end

    test "returns empty attrs for empty input" do
      {:ok, attrs, conflicts} = Transformer.flat_to_nested(%{}, 10)

      assert attrs.assignments == []
      assert attrs.manuals == []
      assert conflicts == []
    end

    test "returns empty attrs for non-map input" do
      {:ok, attrs, conflicts} = Transformer.flat_to_nested(nil, 10)

      assert attrs.assignments == []
      assert attrs.manuals == []
      assert conflicts == []
    end

    test "records conflicts for unknown path patterns" do
      flat = %{
        "next://user-10@localhost/unknown/path/key" => "value"
      }

      {:ok, attrs, conflicts} = Transformer.flat_to_nested(flat, 10)

      assert attrs.assignments == []
      assert length(conflicts) == 1
    end
  end

  describe "nested_to_flat/2" do
    test "transforms assignment crew task back to flat" do
      nested = %{
        assignments: [%{id: 5, crews: [%{id: 3, task: 4}]}],
        manuals: []
      }

      flat = Transformer.nested_to_flat(nested, 10)

      assert flat == %{
               "next://user-10@localhost/assignment/5/crew/3/task" => "4"
             }
    end

    test "transforms manual chapter and page" do
      nested = %{
        assignments: [],
        manuals: [%{id: 5, chapter: 2, page: 10}]
      }

      flat = Transformer.nested_to_flat(nested, 10)

      assert "next://user-10@localhost/manual/5/chapter" in Map.keys(flat)
      assert "next://user-10@localhost/manual/5/page" in Map.keys(flat)
    end

    test "skips nil task values" do
      nested = %{
        assignments: [%{id: 5, crews: [%{id: 3, task: nil}]}],
        manuals: []
      }

      flat = Transformer.nested_to_flat(nested, 10)

      assert flat == %{}
    end

    test "skips nil manual values" do
      nested = %{
        assignments: [],
        manuals: [%{id: 5, chapter: nil, page: nil}]
      }

      flat = Transformer.nested_to_flat(nested, 10)

      assert flat == %{}
    end
  end
end
