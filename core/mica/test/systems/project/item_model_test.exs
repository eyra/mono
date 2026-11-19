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

    refute Map.get(item_card(item), :icon_url)
  end

  test "Data item card without donations shows the empty illustration and No data" do
    creator = Factories.insert!(:creator)
    {:ok, %{storage_setup: %{item: item}}} = Project.Assembly.create("Project", creator, :empty)

    assert %{
             type: :data,
             label: nil,
             illustration: "data_card_no_data.png",
             info: ["No data"]
           } = item_card(item)
  end

  test "Data item card with donations shows the illustration with data and the file count" do
    creator = Factories.insert!(:creator)

    {:ok, %{storage_setup: %{item: item, endpoint: endpoint}}} =
      Project.Assembly.create("Project", creator, :empty)

    Systems.Monitor.Public.log({endpoint, :files})

    assert %{
             type: :data,
             label: nil,
             illustration: "data_card_has_data.png",
             info: ["1 file"]
           } = item_card(item)
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
