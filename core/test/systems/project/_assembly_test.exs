defmodule Systems.Project.AssemblyTest do
  use Core.DataCase

  alias Systems.Assignment.Model
  alias Systems.Project
  alias Systems.Project.ItemModel
  alias Systems.Project.NodeModel

  test "create_item/3 create benchmark item" do
    user = Factories.insert!(:member)

    %{root: %{id: root_id} = root} = Factories.insert!(:project, %{name: "Project"})

    item_name = "Item"

    {:ok, %{project_item: %{id: id}}} =
      Project.Assembly.create_item(:benchmark_challenge, item_name, root, user)

    item = Project.Public.get_item!(id, ItemModel.preload_graph(:down))

    assert %ItemModel{
             name: ^item_name,
             project_path: [^root_id],
             assignment: %Model{
               special: :benchmark_challenge,
               status: :concept,
               external_panel: nil,
               workflow: %Systems.Workflow.Model{
                 items: [
                   %Systems.Workflow.ItemModel{},
                   %Systems.Workflow.ItemModel{},
                   %Systems.Workflow.ItemModel{}
                 ]
               }
             }
           } = item
  end

  test "create_item/3 create data donation item" do
    user = Factories.insert!(:member)

    %{root: %{id: root_id} = root} = Factories.insert!(:project, %{name: "Project"})

    item_name = "Item"

    {:ok, %{project_item: %{id: id}}} =
      Project.Assembly.create_item(:data_donation, item_name, root, user)

    item = Project.Public.get_item!(id, ItemModel.preload_graph(:down))

    assert %{
             name: ^item_name,
             project_path: [^root_id],
             assignment: %Model{
               info: %Systems.Assignment.InfoModel{},
               workflow: %Systems.Workflow.Model{
                 items: []
               },
               crew: %Systems.Crew.Model{
                 tasks: [],
                 members: [],
                 auth_node: %Core.Authorization.Node{}
               },
               budget: nil,
               auth_node: %Core.Authorization.Node{
                 role_assignments: []
               },
               excluded: []
             }
           } = item
  end

  test "update_path/1 succeeds with project and node depth of 1" do
    item1 = Project.Factories.build_item(Project.Factories.build_assignment())

    item2 = Project.Factories.build_item(Project.Factories.build_assignment())

    %{id: project_id} =
      project =
      [items: [item1, item2]]
      |> Project.Factories.build_node()
      |> Project.Factories.build_project()
      |> Repo.insert!()

    assert %Systems.Project.Model{
             root: %NodeModel{
               id: root_id,
               project_path: [],
               items: [
                 %ItemModel{
                   project_path: []
                 },
                 %ItemModel{
                   project_path: []
                 }
               ]
             }
           } = Project.Model |> Repo.get!(project_id) |> Repo.preload(root: [:items])

    {:ok, _} =
      Ecto.Multi.new()
      |> Project.Assembly.update_path(project)
      |> Repo.commit()

    assert %Systems.Project.Model{
             root: %NodeModel{
               project_path: [^project_id],
               items: [
                 %ItemModel{
                   project_path: [^project_id, ^root_id]
                 },
                 %ItemModel{
                   project_path: [^project_id, ^root_id]
                 }
               ]
             }
           } = Project.Model |> Repo.get!(project_id) |> Repo.preload(root: [:items])
  end

  test "update_path/1 succeeds with project and node depth of 2" do
    item_a_1 = Project.Factories.build_item(Project.Factories.build_assignment())

    item_a_2 = Project.Factories.build_item(Project.Factories.build_assignment())

    item_b_1 = Project.Factories.build_item(Project.Factories.build_assignment())

    item_b_2 = Project.Factories.build_item(Project.Factories.build_assignment())

    node_a = Project.Factories.build_node(items: [item_a_1, item_a_2])
    node_b = Project.Factories.build_node(items: [item_b_1, item_b_2])

    %{id: project_id} =
      project =
      [children: [node_a, node_b]]
      |> Project.Factories.build_node()
      |> Project.Factories.build_node()
      |> Project.Factories.build_project()
      |> Repo.insert!()

    assert %Systems.Project.Model{
             root: %NodeModel{
               id: level1,
               project_path: [],
               children: [
                 %NodeModel{
                   id: level2,
                   project_path: [],
                   children: level_2_children
                 }
               ]
             }
           } =
             Project.Model
             |> Repo.get!(project_id)
             |> Repo.preload(root: [children: [children: [:items]]])

    assert [
             %NodeModel{
               id: level_3_a,
               project_path: [],
               items: [%ItemModel{project_path: []}, %ItemModel{project_path: []}]
             },
             %NodeModel{
               id: level_3_b,
               project_path: [],
               items: [%ItemModel{project_path: []}, %ItemModel{project_path: []}]
             }
           ] = Enum.sort_by(level_2_children, & &1.id)

    {:ok, _} =
      Ecto.Multi.new()
      |> Project.Assembly.update_path(project)
      |> Repo.commit()

    assert %Systems.Project.Model{
             root: %NodeModel{
               project_path: [^project_id],
               children: [
                 %NodeModel{
                   project_path: [^project_id, ^level1],
                   children: [
                     %NodeModel{
                       project_path: [^project_id, ^level1, ^level2],
                       items: [
                         %ItemModel{
                           project_path: [^project_id, ^level1, ^level2, ^level_3_a]
                         },
                         %ItemModel{
                           project_path: [^project_id, ^level1, ^level2, ^level_3_a]
                         }
                       ]
                     },
                     %NodeModel{
                       project_path: [^project_id, ^level1, ^level2],
                       items: [
                         %ItemModel{
                           project_path: [^project_id, ^level1, ^level2, ^level_3_b]
                         },
                         %ItemModel{
                           project_path: [^project_id, ^level1, ^level2, ^level_3_b]
                         }
                       ]
                     }
                   ]
                 }
               ]
             }
           } =
             Project.Model
             |> Repo.get!(project_id)
             |> Repo.preload(root: [children: [children: [:items]]])
  end
end
