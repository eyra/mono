defmodule Systems.Project.AssemblyTest do
  use Core.DataCase

  alias Systems.Project

  test "create_item/3 create benchmark item" do
    user = Factories.insert!(:member)

    %{root: %{id: root_id} = root} = Factories.insert!(:project, %{name: "Project"})

    item_name = "Item"

    {:ok, %{project_item: %{id: id}}} =
      Project.Assembly.create_item(:benchmark_challenge, item_name, root, user)

    item = Project.Public.get_item!(id, Project.ItemModel.preload_graph(:down))

    assert %Systems.Project.ItemModel{
             name: ^item_name,
             project_path: [^root_id],
             assignment: %Systems.Assignment.Model{
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

    item = Project.Public.get_item!(id, Project.ItemModel.preload_graph(:down))

    assert %{
             name: ^item_name,
             project_path: [^root_id],
             assignment: %Systems.Assignment.Model{
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
    item1 =
      Project.Factories.build_assignment()
      |> Project.Factories.build_item()

    item2 =
      Project.Factories.build_assignment()
      |> Project.Factories.build_item()

    %{id: project_id} =
      project =
      Project.Factories.build_node(items: [item1, item2])
      |> Project.Factories.build_project()
      |> Repo.insert!()

    assert %Systems.Project.Model{
             root: %Systems.Project.NodeModel{
               id: root_id,
               project_path: [],
               items: [
                 %Systems.Project.ItemModel{
                   project_path: []
                 },
                 %Systems.Project.ItemModel{
                   project_path: []
                 }
               ]
             }
           } = Repo.get!(Project.Model, project_id) |> Repo.preload(root: [:items])

    {:ok, _} =
      Ecto.Multi.new()
      |> Project.Assembly.update_path(project)
      |> Repo.commit()

    assert %Systems.Project.Model{
             root: %Systems.Project.NodeModel{
               project_path: [^project_id],
               items: [
                 %Systems.Project.ItemModel{
                   project_path: [^project_id, ^root_id]
                 },
                 %Systems.Project.ItemModel{
                   project_path: [^project_id, ^root_id]
                 }
               ]
             }
           } = Repo.get!(Project.Model, project_id) |> Repo.preload(root: [:items])
  end

  test "update_path/1 succeeds with project and node depth of 2" do
    item_a_1 =
      Project.Factories.build_assignment()
      |> Project.Factories.build_item()

    item_a_2 =
      Project.Factories.build_assignment()
      |> Project.Factories.build_item()

    item_b_1 =
      Project.Factories.build_assignment()
      |> Project.Factories.build_item()

    item_b_2 =
      Project.Factories.build_assignment()
      |> Project.Factories.build_item()

    node_a = Project.Factories.build_node(items: [item_a_1, item_a_2])
    node_b = Project.Factories.build_node(items: [item_b_1, item_b_2])

    %{id: project_id} =
      project =
      Project.Factories.build_node(children: [node_a, node_b])
      |> Project.Factories.build_node()
      |> Project.Factories.build_project()
      |> Repo.insert!()

    assert %Systems.Project.Model{
             root: %Systems.Project.NodeModel{
               id: level1,
               project_path: [],
               children: [
                 %Systems.Project.NodeModel{
                   id: level2,
                   project_path: [],
                   children: level_2_children
                 }
               ]
             }
           } =
             Repo.get!(Project.Model, project_id)
             |> Repo.preload(root: [children: [children: [:items]]])

    assert [
             %Systems.Project.NodeModel{
               id: level_3_a,
               project_path: [],
               items: [
                 %Systems.Project.ItemModel{
                   project_path: []
                 },
                 %Systems.Project.ItemModel{
                   project_path: []
                 }
               ]
             },
             %Systems.Project.NodeModel{
               id: level_3_b,
               project_path: [],
               items: [
                 %Systems.Project.ItemModel{
                   project_path: []
                 },
                 %Systems.Project.ItemModel{
                   project_path: []
                 }
               ]
             }
           ] = level_2_children |> Enum.sort_by(& &1.id)

    {:ok, _} =
      Ecto.Multi.new()
      |> Project.Assembly.update_path(project)
      |> Repo.commit()

    assert %Systems.Project.Model{
             root: %Systems.Project.NodeModel{
               project_path: [^project_id],
               children: [
                 %Systems.Project.NodeModel{
                   project_path: [^project_id, ^level1],
                   children: [
                     %Systems.Project.NodeModel{
                       project_path: [^project_id, ^level1, ^level2],
                       items: [
                         %Systems.Project.ItemModel{
                           project_path: [^project_id, ^level1, ^level2, ^level_3_a]
                         },
                         %Systems.Project.ItemModel{
                           project_path: [^project_id, ^level1, ^level2, ^level_3_a]
                         }
                       ]
                     },
                     %Systems.Project.NodeModel{
                       project_path: [^project_id, ^level1, ^level2],
                       items: [
                         %Systems.Project.ItemModel{
                           project_path: [^project_id, ^level1, ^level2, ^level_3_b]
                         },
                         %Systems.Project.ItemModel{
                           project_path: [^project_id, ^level1, ^level2, ^level_3_b]
                         }
                       ]
                     }
                   ]
                 }
               ]
             }
           } =
             Repo.get!(Project.Model, project_id)
             |> Repo.preload(root: [children: [children: [:items]]])
  end
end
