defmodule Next.Systems.Graphite.LeaderboardPageBuilderTest do
  use Mica.DataCase

  alias Frameworks.Utility.ViewModelBuilder
  alias Next.Systems.Graphite
  alias Systems.Project

  describe "challenge task deleted" do
    setup do
      challenge = Graphite.Factories.create_challenge() |> Repo.preload(:workflow)
      tool = Graphite.Factories.add_tool(challenge)

      leaderboard =
        Graphite.Factories.create_leaderboard(tool, %{
          title: "Leaderboard",
          status: :online,
          visibility: :public,
          metrics: []
        })

      tool
      |> Systems.Workflow.Public.get_item_by_tool()
      |> Repo.delete!()

      user = Factories.insert!(:member)

      %{leaderboard: leaderboard, user: user}
    end

    test "leaderboard page shows without challenge info", %{
      leaderboard: leaderboard,
      user: user
    } do
      assert %{info: nil, title: "Leaderboard"} =
               Graphite.LeaderboardPageBuilder.view_model(leaderboard, %{current_user: user})
    end

    test "project card shows without challenge image", %{leaderboard: leaderboard} do
      item =
        Factories.insert!(:project_item, %{
          name: "Leaderboard",
          project_path: [],
          node: Factories.build(:project_node),
          leaderboard: leaderboard
        })
        |> Repo.preload(Project.ItemModel.preload_graph(:down))

      assert %{image_info: nil, icon_url: nil} =
               ViewModelBuilder.view_model(item, {Project.NodePage, :item_card}, %{
                 timezone: "Europe/Amsterdam"
               })
    end
  end
end
