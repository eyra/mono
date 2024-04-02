defmodule Systems.Graphite.PublicTest do
  use Core.DataCase

  alias Core.Factories
  alias Core.Repo

  alias Systems.{
    Graphite
  }

  test "import_csv_lines/2 one line" do
    metric1 = "aap"
    metric2 = "noot"
    metric3 = "mies"
    metrics = [metric1, metric2, metric3]

    metric1_score = 0.1
    metric2_score = 0.2
    metric3_score = 0.3

    name = "Team1"
    board_name = "test board"
    tool = create_tool()
    auth_node = create_auth_node()
    leaderboard = create_leaderboard(board_name, metrics)
    submission = create_submission(tool)

    csv_line = %{
      "submission" => "#{submission.id}",
      metric1 => "#{metric1_score}",
      metric2 => "#{metric2_score}",
      metric3 => "#{metric3_score}"
    }

    {:ok, result} = Graphite.Public.import_csv_lines(leaderboard, [csv_line])

    assert Enum.count(Map.keys(result)) == 2

    assert count_scores() == 3

    assert %{
             add_scores:
               {3,
                [
                  %Systems.Graphite.ScoreModel{
                    score: ^metric1_score
                  },
                  %Systems.Graphite.ScoreModel{
                    score: ^metric2_score
                  },
                  %Systems.Graphite.ScoreModel{
                    score: ^metric3_score
                  }
                ]}
           } = result
  end

  test "import_csv_lines/2 one line with score `0`" do
    board_name = "Test board 2"
    metric1 = "aap"
    metrics = [metric1]

    metric1_score = 0.0

    tool = create_tool()
    auth_node = create_auth_node()
    leaderboard = create_leaderboard(board_name, metrics)
    submission = create_submission(tool)

    csv_line = %{
      metric1 => "#{metric1_score}",
      "submission" => "#{submission.id}"
    }

    {:ok, result} = Graphite.Public.import_csv_lines(leaderboard, [csv_line])

    assert Enum.count(Map.keys(result)) == 2

    submission_id = submission.id

    assert %{
             add_scores:
               {1,
                [
                  %Systems.Graphite.ScoreModel{
                    score: 0.0,
                    submission_id: ^submission_id
                  }
                ]}
           } = result
  end

  test "import_csv_lines/2 two lines two submissions" do
    board_name = "Test board 2"
    metric1 = "aap"
    metrics = [metric1]

    metric1_score = 0.0

    tool = create_tool()
    auth_node = create_auth_node()
    leaderboard = create_leaderboard(board_name, metrics)

    name = "Team1"
    tool = create_tool()
    %{id: submission_id1, description: description1} = create_submission(tool, "Method X")
    %{id: submission_id2, description: description2} = create_submission(tool, "Method Y")

    csv_line1 = %{
      "aap" => "0.1",
      "submission" => "#{submission_id1}"
    }

    csv_line2 = %{
      "aap" => "0.2",
      "submission" => "#{submission_id2}"
    }

    {:ok, result} = Graphite.Public.import_csv_lines(leaderboard, [csv_line1, csv_line2])

    assert Enum.count(Map.keys(result)) == 2

    assert count_leaderboards() == 1
  end

  # FIXME: this now fails for the wrong reason
  test "import_csv_lines/1 two lines one submission should fail" do
    name = "Team1"
    tool = create_tool()
    %{id: submission_id, description: description} = create_submission(tool, "Method X")

    csv_line1 = %{
      "id" => "#{submission_id}:#{name}:#{description}",
      "status" => "success",
      "error_message" => "",
      "cat1" => "0.1"
    }

    csv_line2 = %{
      "id" => "#{submission_id}:#{name}:#{description}",
      "status" => "success",
      "error_message" => "",
      "cat1" => "0.2"
    }

    assert_raise RuntimeError, fn ->
      Graphite.Public.import_csv_lines([csv_line1, csv_line2])
    end
  end

  # Currently does not support this
  # test "import_csv_lines/2 ignore errors" do
  #   name = "Team1"
  #   tool = create_tool()
  #   %{id: submission_id1, description: description1} = create_submission(tool, "Method X")
  #   %{id: submission_id2, description: description2} = create_submission(tool, "Method Y")

  #   csv_line1 = %{
  #     "id" => "#{submission_id1}:#{name}:#{description1}",
  #     "status" => "success",
  #     "error_message" => "",
  #     "cat1" => "0.1"
  #   }

  #   csv_line2 = %{
  #     "id" => "#{submission_id2}:#{name}:#{description2}",
  #     "status" => "error",
  #     "error_message" => "Something went wrong",
  #     "cat1" => ""
  #   }

  #   {:ok, result} = Graphite.Public.import_csv_lines([csv_line1, csv_line2])

  #   assert Enum.count(Map.keys(result)) == 3
  # end

  test "import_csv_lines/2 two version after two imports" do
    board_name = "Test board 2"
    metric1 = "aap"
    metrics = [metric1]

    metric1_score = 0.0

    tool = create_tool()
    auth_node = create_auth_node()
    leaderboard = create_leaderboard(board_name, metrics)

    %{id: submission_id, description: description} = create_submission(tool)

    cat1 = "aap"

    csv_line = %{
      "submission" => "#{submission_id}",
      cat1 => "0.1"
    }

    {:ok, %{add_scores: {1, [result1]}}} =
      Graphite.Public.import_csv_lines(leaderboard, [csv_line])

    {:ok, %{add_scores: {1, [result2]}}} =
      Graphite.Public.import_csv_lines(leaderboard, [csv_line])

    assert result1 < result2
  end

  defp create_auth_node() do
    Core.Authorization.Node.change(%Core.Authorization.Node{})
    |> Repo.insert!()
  end

  defp create_tool() do
    Factories.insert!(:graphite_tool, %{max_submissions: 3})
  end

  defp create_leaderboard(name, metrics) do
    Factories.insert!(
      :graphite_leaderboard,
      %{
        name: name,
        version: "1",
        status: :concept,
        metrics: metrics,
        visibility: :public,
        open_date: ~N[2024-07-01 00:00:00],
        generation_date: nil,
        allow_anonymous: false
      }
    )
  end

  defp create_submission(tool, description \\ "Method X") do
    submission_attr = %{
      tool: tool,
      description: description,
      github_commit_url:
        "https://github.com/eyra/mono/commit/9d10bd2907dda135ebe86511489570dbf8c067c0"
    }

    Factories.insert!(:graphite_submission, submission_attr)
  end

  defp count_scores() do
    Repo.one(
      Ecto.Query.from(
        score in Graphite.ScoreModel,
        select: count(score.id)
      )
    )
  end

  defp count_leaderboards() do
    Repo.one(
      Ecto.Query.from(
        leaderboard in Graphite.LeaderboardModel,
        select: count(leaderboard.id)
      )
    )
  end
end
