defmodule Systems.Project.PublicTest do
  use Core.DataCase

  alias Systems.Project
  alias Systems.Project.ItemModel

  describe "list_items/2" do
    test "one matching item" do
      item =
        :assignment
        |> Core.Factories.build(%{special: :benchmark_challenge})
        |> Project.Factories.build_item()

      %{root: %{id: node_id, items: [item]} = node} =
        [items: [item]]
        |> Project.Factories.build_node()
        |> Project.Factories.build_project()
        |> Repo.insert!()

      %{id: item_id, assignment: %{id: assignment_id}} = item

      assert [
               %ItemModel{
                 id: ^item_id,
                 node_id: ^node_id,
                 assignment_id: ^assignment_id
               }
             ] = Project.Public.list_items(node, {:assignment, :benchmark_challenge})
    end

    test "multiple matching items" do
      item1 =
        :assignment
        |> Core.Factories.build(%{special: :benchmark_challenge})
        |> Project.Factories.build_item()

      item2 =
        :assignment
        |> Core.Factories.build(%{special: :data_donation})
        |> Project.Factories.build_item()

      item3 =
        :assignment
        |> Core.Factories.build(%{special: :benchmark_challenge})
        |> Project.Factories.build_item()

      item4 =
        :assignment
        |> Core.Factories.build(%{special: :data_donation})
        |> Project.Factories.build_item()

      %{root: %{items: [%{id: item_1_id}, _, %{id: item_3_id}, _]} = node} =
        [items: [item1, item2, item3, item4]]
        |> Project.Factories.build_node()
        |> Project.Factories.build_project()
        |> Repo.insert!()

      assert [
               %ItemModel{id: ^item_1_id},
               %ItemModel{id: ^item_3_id}
             ] = Project.Public.list_items(node, {:assignment, :benchmark_challenge})
    end

    test "no matching items" do
      item1 =
        :assignment
        |> Core.Factories.build(%{special: :data_donation})
        |> Project.Factories.build_item()

      item2 =
        :assignment
        |> Core.Factories.build(%{special: :data_donation})
        |> Project.Factories.build_item()

      %{root: node} =
        [items: [item1, item2]]
        |> Project.Factories.build_node()
        |> Project.Factories.build_project()
        |> Repo.insert!()

      assert [] = Project.Public.list_items(node, {:assignment, :benchmark_challenge})
    end

    test "no items" do
      %{root: node} =
        [items: []]
        |> Project.Factories.build_node()
        |> Project.Factories.build_project()
        |> Repo.insert!()

      assert [] = Project.Public.list_items(node, {:assignment, :benchmark_challenge})
    end
  end

  describe "get_node_id_by/1" do
    setup do
      assignment = Core.Factories.build(:assignment)
      item = Project.Factories.build_item(assignment)

      %{root: %{id: node_id, items: [%{assignment: %{id: assignment_id}}]}} =
        [items: [item]]
        |> Project.Factories.build_node()
        |> Project.Factories.build_project()
        |> Repo.insert!()

      %{assignment_id: assignment_id, node_id: node_id}
    end

    test "returns node_id for an assignment struct", %{
      assignment_id: assignment_id,
      node_id: node_id
    } do
      assert ^node_id =
               Project.Public.get_node_id_by(%Systems.Assignment.Model{id: assignment_id})
    end

    test "returns node_id for an integer assignment_id", %{
      assignment_id: assignment_id,
      node_id: node_id
    } do
      assert ^node_id = Project.Public.get_node_id_by(assignment_id)
    end

    test "returns nil when no project item exists for the assignment" do
      assert nil == Project.Public.get_node_id_by(-1)
    end
  end
end
