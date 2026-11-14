defmodule Systems.Project.ModelTest do
  alias Mica.Authorization
  use Mica.DataCase

  alias Systems.{
    Project
  }

  test "overview card counts the Data item" do
    creator = Factories.insert!(:creator)
    {:ok, %{project: project}} = Project.Assembly.create("Project", creator, :empty)
    project = Repo.preload(project, [root: :items], force: true)

    assert %{info: ["1 item"]} =
             Frameworks.Utility.ViewModelBuilder.view_model(
               project,
               {Project.OverviewPage, :card},
               %{current_user: creator}
             )
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
             %Authorization.Node{id: project_id},
             {
               %Authorization.Node{id: node_id},
               [
                 %Authorization.Node{id: assignment_id}
               ]
             }
           } = auth_tree

    assert %Authorization.Node{
             id: ^project_id,
             children: []
           } =
             Repo.get!(Authorization.Node, project_id) |> Repo.preload(children: [:children])

    Authorization.link(auth_tree)

    assert %Authorization.Node{
             id: ^project_id,
             children: [
               %Authorization.Node{
                 id: ^node_id,
                 children: [
                   %Authorization.Node{
                     id: ^assignment_id
                   }
                 ]
               }
             ]
           } =
             Repo.get!(Authorization.Node, project_id) |> Repo.preload(children: [:children])
  end
end
