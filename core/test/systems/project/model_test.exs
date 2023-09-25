defmodule Systems.Project.ModelTest do
  use Core.DataCase

  alias Systems.{
    Project
  }

  test "auth_tree/1 succeeds with tool_ref item" do
    project =
      Project.Factories.build_tool()
      |> Project.Factories.build_tool_ref()
      |> Project.Factories.build_item()
      |> Project.Factories.build_node()
      |> Project.Factories.build_project()
      |> Repo.insert!()

    auth_tree = Project.Model.auth_tree(project)

    assert {
             %Core.Authorization.Node{id: project_id},
             {
               %Core.Authorization.Node{id: node_id},
               [
                 %Core.Authorization.Node{id: tool_id}
               ]
             }
           } = auth_tree

    assert %Core.Authorization.Node{
             id: ^tool_id,
             parent_id: nil
           } = Repo.get!(Core.Authorization.Node, tool_id) |> Repo.preload(parent: [:parent])

    Core.Authorization.link(auth_tree)

    assert %Core.Authorization.Node{
             id: ^tool_id,
             parent: %Core.Authorization.Node{
               id: ^node_id,
               parent: %Core.Authorization.Node{
                 id: ^project_id,
                 parent_id: nil
               }
             }
           } = Repo.get!(Core.Authorization.Node, tool_id) |> Repo.preload(parent: [:parent])
  end

  test "auth_tree/1 succeeds with assignment item" do
    project =
      Project.Factories.build_assignment()
      |> Project.Factories.build_item()
      |> Project.Factories.build_node()
      |> Project.Factories.build_project()
      |> Repo.insert!()

    auth_tree = Project.Model.auth_tree(project)

    assert {
             %Core.Authorization.Node{id: project_id},
             {
               %Core.Authorization.Node{id: node_id},
               [
                 %Core.Authorization.Node{id: assignment_id}
               ]
             }
           } = auth_tree

    assert %Core.Authorization.Node{
             id: ^project_id,
             children: []
           } =
             Repo.get!(Core.Authorization.Node, project_id) |> Repo.preload(children: [:children])

    Core.Authorization.link(auth_tree)

    assert %Core.Authorization.Node{
             id: ^project_id,
             children: [
               %Core.Authorization.Node{
                 id: ^node_id,
                 children: [
                   %Core.Authorization.Node{
                     id: ^assignment_id
                   }
                 ]
               }
             ]
           } =
             Repo.get!(Core.Authorization.Node, project_id) |> Repo.preload(children: [:children])
  end
end
