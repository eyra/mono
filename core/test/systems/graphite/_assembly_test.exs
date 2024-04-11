defmodule Systems.Graphite.AssemblyTest do
  use Core.DataCase

  alias Core.Repo
  alias Systems.Project
  alias Systems.Graphite.Assembly
  alias Systems.Graphite.Factories

  describe "get_leaderboard_name/1" do
    test "without other leaderboard" do
      project_node =
        Project.Factories.build_node(items: [])
        |> Repo.insert!()

      assert "Benchmark Leaderboard 1" = Assembly.get_leaderboard_name(project_node)
    end

    test "with other leaderboards" do
      challenge_1 = Factories.create_challenge()
      challenge_2 = Factories.create_challenge()

      tool_1 = Factories.add_tool(challenge_1)
      tool_2 = Factories.add_tool(challenge_2)

      leaderboard_1 = Factories.create_leaderboard(tool_1)
      leaderboard_2 = Factories.create_leaderboard(tool_2)

      challenge_1_item = Project.Factories.build_item(challenge_1)
      challenge_2_item = Project.Factories.build_item(challenge_2)

      leaderboard_1_item = Project.Factories.build_item(leaderboard_1)
      leaderboard_2_item = Project.Factories.build_item(leaderboard_2)

      project_node =
        Project.Factories.build_node(
          items: [challenge_1_item, challenge_2_item, leaderboard_1_item, leaderboard_2_item]
        )
        |> Repo.insert!()

      assert "Benchmark Leaderboard 3" = Assembly.get_leaderboard_name(project_node)
    end
  end

  describe "create_leaderboard/1" do
    test "without benchmark challenge" do
      tool = Factories.create_tool()

      assert_raise RuntimeError, fn ->
        Assembly.create_leaderboard(tool)
      end
    end

    test "with benchmark challenge" do
      challenge = Factories.create_challenge()
      tool = %{id: tool_id} = Factories.add_tool(challenge)

      challenge_item = Project.Factories.build_item(challenge)

      %{root_id: project_root_id} =
        Project.Factories.build_node(items: [challenge_item])
        |> Project.Factories.build_project()
        |> Repo.insert!()

      {:ok, %{project_item: project_item}} = Assembly.create_leaderboard(tool)

      assert %Systems.Project.ItemModel{
               project_path: [^project_root_id],
               leaderboard: %Systems.Graphite.LeaderboardModel{
                 tool: %Systems.Graphite.ToolModel{id: ^tool_id},
                 auth_node: %Core.Authorization.Node{},
                 project_item: %Ecto.Association.NotLoaded{}
               }
             } = project_item
    end
  end
end
