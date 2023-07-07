defmodule Systems.Project.AssemblyTest do
  use Core.DataCase

  alias Systems.{
    Project
  }

  test "create_item/3 create benchmark item" do
    %{id: project_id, root: %{id: root_id} = root} =
      Factories.insert!(:project, %{name: "Project"})

    item_name = "Item"

    assert {:ok,
            %{
              item: %Systems.Project.ItemModel{
                name: ^item_name,
                project_path: [^project_id, ^root_id],
                node_id: ^root_id,
                tool_ref: %Systems.Project.ToolRefModel{
                  questionnaire_tool_id: nil,
                  lab_tool_id: nil,
                  data_donation_tool_id: nil,
                  benchmark_tool: %Systems.Benchmark.ToolModel{
                    status: :concept,
                    director: :project
                  }
                }
              }
            }} = Project.Assembly.create_item(item_name, root, :benchmark)
  end

  test "create_item/3 create data donation item" do
    %{id: project_id, root: %{id: root_id} = root} =
      Factories.insert!(:project, %{name: "Project"})

    item_name = "Item"

    assert {:ok,
            %{
              item: %Systems.Project.ItemModel{
                name: ^item_name,
                project_path: [^project_id, ^root_id],
                node_id: ^root_id,
                tool_ref: %Systems.Project.ToolRefModel{
                  questionnaire_tool_id: nil,
                  lab_tool_id: nil,
                  data_donation_tool: %Systems.DataDonation.ToolModel{
                    status: :concept,
                    director: :project
                  },
                  benchmark_tool_id: nil
                }
              }
            }} = Project.Assembly.create_item(item_name, root, :data_donation)
  end
end
