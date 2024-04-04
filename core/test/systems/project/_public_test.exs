defmodule Systems.Project.PublicTest do
  use Core.DataCase

  alias Systems.Project

  describe "list_items/2" do
    test "one matching item" do
      item =
        Core.Factories.build(:assignment, %{special: :benchmark_challenge})
        |> Project.Factories.build_item()

      %{root: %{id: node_id, items: [item]} = node} =
        Project.Factories.build_node(items: [item])
        |> Project.Factories.build_project()
        |> Repo.insert!()

      %{id: item_id, assignment: %{id: assignment_id}} = item

      assert [
               %Systems.Project.ItemModel{
                 id: ^item_id,
                 node_id: ^node_id,
                 assignment_id: ^assignment_id
               }
             ] = Project.Public.list_items(node, {:assignment, :benchmark_challenge})
    end

    test "multiple matching items" do
      item1 =
        Core.Factories.build(:assignment, %{special: :benchmark_challenge})
        |> Project.Factories.build_item()

      item2 =
        Core.Factories.build(:assignment, %{special: :data_donation})
        |> Project.Factories.build_item()

      item3 =
        Core.Factories.build(:assignment, %{special: :benchmark_challenge})
        |> Project.Factories.build_item()

      item4 =
        Core.Factories.build(:assignment, %{special: :data_donation})
        |> Project.Factories.build_item()

      %{root: %{items: [%{id: item_1_id}, _, %{id: item_3_id}, _]} = node} =
        Project.Factories.build_node(items: [item1, item2, item3, item4])
        |> Project.Factories.build_project()
        |> Repo.insert!()

      assert [
               %Systems.Project.ItemModel{id: ^item_1_id},
               %Systems.Project.ItemModel{id: ^item_3_id}
             ] = Project.Public.list_items(node, {:assignment, :benchmark_challenge})
    end

    test "no matching items" do
      item1 =
        Core.Factories.build(:assignment, %{special: :data_donation})
        |> Project.Factories.build_item()

      item2 =
        Core.Factories.build(:assignment, %{special: :data_donation})
        |> Project.Factories.build_item()

      %{root: node} =
        Project.Factories.build_node(items: [item1, item2])
        |> Project.Factories.build_project()
        |> Repo.insert!()

      assert [] = Project.Public.list_items(node, {:assignment, :benchmark_challenge})
    end

    test "no items" do
      %{root: node} =
        Project.Factories.build_node(items: [])
        |> Project.Factories.build_project()
        |> Repo.insert!()

      assert [] = Project.Public.list_items(node, {:assignment, :benchmark_challenge})
    end
  end
end
