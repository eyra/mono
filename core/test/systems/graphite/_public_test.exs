defmodule Systems.Graphite.PublicTest do
  use Core.DataCase

  alias Systems.Graphite
  alias Systems.Graphite.Factories

  describe "list_submissions/1" do
    test "no submissions" do
      challenge = Factories.create_challenge()
      assert [] = Graphite.Public.list_submissions(challenge)
    end

    test "one submission" do
      challenge = Factories.create_challenge()
      tool = %{id: tool_id} = Factories.add_tool(challenge)
      %{id: submission_id} = Factories.add_submission(tool)

      assert [
               %Systems.Graphite.SubmissionModel{id: ^submission_id, tool_id: ^tool_id}
             ] = Graphite.Public.list_submissions(challenge)
    end

    test "multiple submissions" do
      challenge = Factories.create_challenge()
      tool = %{id: tool_id} = Factories.add_tool(challenge)
      %{id: submission1_id} = Factories.add_submission(tool)
      %{id: submission2_id} = Factories.add_submission(tool)
      %{id: submission3_id} = Factories.add_submission(tool)

      assert [
               %Systems.Graphite.SubmissionModel{id: ^submission1_id, tool_id: ^tool_id},
               %Systems.Graphite.SubmissionModel{id: ^submission2_id, tool_id: ^tool_id},
               %Systems.Graphite.SubmissionModel{id: ^submission3_id, tool_id: ^tool_id}
             ] = Graphite.Public.list_submissions(challenge)
    end

    test "multiple tools and submissions" do
      challenge = Factories.create_challenge()
      tool1 = %{id: tool1_id} = Factories.add_tool(challenge)
      tool2 = %{id: tool2_id} = Factories.add_tool(challenge)

      %{id: submission1_id} = Factories.add_submission(tool1)
      %{id: submission2_id} = Factories.add_submission(tool1)
      %{id: submission3_id} = Factories.add_submission(tool2)
      %{id: submission4_id} = Factories.add_submission(tool2)

      assert [
               %Systems.Graphite.SubmissionModel{id: ^submission1_id, tool_id: ^tool1_id},
               %Systems.Graphite.SubmissionModel{id: ^submission2_id, tool_id: ^tool1_id},
               %Systems.Graphite.SubmissionModel{id: ^submission3_id, tool_id: ^tool2_id},
               %Systems.Graphite.SubmissionModel{id: ^submission4_id, tool_id: ^tool2_id}
             ] = Graphite.Public.list_submissions(challenge)
    end
  end

  test "import_csv_lines/1 one line" do
    name = "Team1"
    tool = Factories.create_tool()
    %{id: submission_id, description: description} = Factories.create_submission(tool)

    cat1 = "aap"
    cat2 = "noot"
    cat3 = "mies"

    cat1_score = 0.1
    cat2_score = 0.2
    cat3_score = 0.3

    csv_line = %{
      "id" => "#{submission_id}:#{name}:#{description}",
      "status" => "success",
      "error_message" => "",
      cat1 => "#{cat1_score}",
      cat2 => "#{cat2_score}",
      cat3 => "#{cat3_score}"
    }

    {:ok, result} = Graphite.Public.import_csv_lines([csv_line])

    cat1_score_key = "#{cat1}-#{submission_id}"
    cat2_score_key = "#{cat2}-#{submission_id}"
    cat3_score_key = "#{cat3}-#{submission_id}"

    assert Enum.count(Map.keys(result)) == 7

    assert count_leaderboards() == 3
    assert count_scores() == 3

    assert %{
             {:leaderboard, ^cat1} => %Systems.Graphite.LeaderboardModel{
               name: ^cat1
             },
             {:leaderboard, ^cat2} => %Systems.Graphite.LeaderboardModel{
               name: ^cat2
             },
             {:leaderboard, ^cat3} => %Systems.Graphite.LeaderboardModel{
               name: ^cat3
             },
             {:score, ^cat1_score_key} => %Systems.Graphite.ScoreModel{
               score: ^cat1_score,
               submission_id: ^submission_id
             },
             {:score, ^cat2_score_key} => %Systems.Graphite.ScoreModel{
               score: ^cat2_score,
               submission_id: ^submission_id
             },
             {:score, ^cat3_score_key} => %Systems.Graphite.ScoreModel{
               score: ^cat3_score,
               submission_id: ^submission_id
             }
           } = result
  end

  test "import_csv_lines/1 one line with score `0`" do
    name = "Team1"
    tool = Factories.create_tool()
    %{id: submission_id, description: description} = Factories.create_submission(tool)

    cat1 = "aap"

    csv_line = %{
      "id" => "#{submission_id}:#{name}:#{description}",
      "status" => "success",
      "error_message" => "",
      cat1 => "0"
    }

    {:ok, result} = Graphite.Public.import_csv_lines([csv_line])

    cat1_score_key = "#{cat1}-#{submission_id}"

    assert Enum.count(Map.keys(result)) == 3

    assert count_leaderboards() == 1
    assert count_scores() == 1

    assert %{
             {:leaderboard, ^cat1} => %Systems.Graphite.LeaderboardModel{
               name: ^cat1
             },
             {:score, ^cat1_score_key} => %Systems.Graphite.ScoreModel{
               score: 0.0,
               submission_id: ^submission_id
             }
           } = result
  end

  test "import_csv_lines/1 one line with empty score" do
    name = "Team1"
    tool = Factories.create_tool()
    %{id: submission_id, description: description} = Factories.create_submission(tool)

    cat1 = "aap"

    csv_line = %{
      "id" => "#{submission_id}:#{name}:#{description}",
      "status" => "success",
      "error_message" => "",
      cat1 => ""
    }

    {:ok, result} = Graphite.Public.import_csv_lines([csv_line])

    cat1_score_key = "#{cat1}-#{submission_id}"

    assert Enum.count(Map.keys(result)) == 3

    assert count_leaderboards() == 1
    assert count_scores() == 1

    assert %{
             {:leaderboard, ^cat1} => %Systems.Graphite.LeaderboardModel{
               name: ^cat1
             },
             {:score, ^cat1_score_key} => %Systems.Graphite.ScoreModel{
               score: 0.0,
               submission_id: ^submission_id
             }
           } = result
  end

  test "import_csv_lines/1 two lines two submissions" do
    name = "Team1"
    tool = Factories.create_tool()

    %{id: submission_id1, description: description1} =
      Factories.create_submission(tool, "Method X")

    %{id: submission_id2, description: description2} =
      Factories.create_submission(tool, "Method Y")

    csv_line1 = %{
      "id" => "#{submission_id1}:#{name}:#{description1}",
      "status" => "success",
      "error_message" => "",
      "cat1" => "0.1"
    }

    csv_line2 = %{
      "id" => "#{submission_id2}:#{name}:#{description2}",
      "status" => "success",
      "error_message" => "",
      "cat1" => "0.2"
    }

    {:ok, result} = Graphite.Public.import_csv_lines([csv_line1, csv_line2])

    assert Enum.count(Map.keys(result)) == 4

    assert count_leaderboards() == 1
    assert count_scores() == 2
  end

  test "import_csv_lines/1 two lines one submission should fail" do
    name = "Team1"
    tool = Factories.create_tool()
    %{id: submission_id, description: description} = Factories.create_submission(tool, "Method X")

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

  test "import_csv_lines/1 ignore errors" do
    name = "Team1"
    tool = Factories.create_tool()

    %{id: submission_id1, description: description1} =
      Factories.create_submission(tool, "Method X")

    %{id: submission_id2, description: description2} =
      Factories.create_submission(tool, "Method Y")

    csv_line1 = %{
      "id" => "#{submission_id1}:#{name}:#{description1}",
      "status" => "success",
      "error_message" => "",
      "cat1" => "0.1"
    }

    csv_line2 = %{
      "id" => "#{submission_id2}:#{name}:#{description2}",
      "status" => "error",
      "error_message" => "Something went wrong",
      "cat1" => ""
    }

    {:ok, result} = Graphite.Public.import_csv_lines([csv_line1, csv_line2])

    assert Enum.count(Map.keys(result)) == 3
  end

  test "import_csv_lines/1 two version after two imports" do
    name = "Team1"
    tool = Factories.create_tool()
    %{id: submission_id, description: description} = Factories.create_submission(tool)

    cat1 = "aap"

    csv_line = %{
      "id" => "#{submission_id}:#{name}:#{description}",
      "status" => "success",
      "error_message" => "",
      cat1 => ""
    }

    {:ok, %{version: version1}} = Graphite.Public.import_csv_lines([csv_line])
    {:ok, %{version: version2}} = Graphite.Public.import_csv_lines([csv_line])

    assert version1 < version2

    assert count_leaderboards() == 2
    assert count_scores() == 2
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
