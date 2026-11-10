defmodule Systems.Project.ItemModelTest do
  use Mica.DataCase

  alias Frameworks.Utility.ViewModelBuilder
  alias Systems.Project

  defp item_card(item) do
    item
    |> Repo.preload(Project.ItemModel.preload_graph(:down))
    |> ViewModelBuilder.view_model({Project.NodePage, :item_card}, %{
      timezone: "Europe/Amsterdam"
    })
  end

  test "Data item card has no rename or delete" do
    creator = Factories.insert!(:creator)

    {:ok, %{storage_setup: %{item: item, endpoint: %{id: endpoint_id}}}} =
      Project.Assembly.create("Project", creator, :empty)

    expected_path = "/storage/endpoint/#{endpoint_id}/content"

    assert %{left_actions: [], right_actions: [], path: ^expected_path} = item_card(item)
  end

  test "Data item card has no icon" do
    creator = Factories.insert!(:creator)
    {:ok, %{storage_setup: %{item: item}}} = Project.Assembly.create("Project", creator, :empty)

    assert %{icon_url: nil} = item_card(item)
  end

  test "Data item card has no image" do
    creator = Factories.insert!(:creator)
    {:ok, %{storage_setup: %{item: item}}} = Project.Assembly.create("Project", creator, :empty)

    assert %{image_info: nil} = item_card(item)
  end

  test "Data item card has a tertiary Storage label instead of a status" do
    creator = Factories.insert!(:creator)
    {:ok, %{storage_setup: %{item: item}}} = Project.Assembly.create("Project", creator, :empty)

    assert %{label: %{type: :tertiary, text: "Storage"}} = item_card(item)
  end

  test "item named Data without storage keeps rename and delete" do
    item =
      Project.Factories.build_assignment()
      |> Project.Factories.build_item("Data")
      |> Project.Factories.build_node()
      |> Repo.insert!()
      |> then(fn %{items: [item]} -> item end)

    assert %{left_actions: [_rename], right_actions: [_delete]} = item_card(item)
  end
end
