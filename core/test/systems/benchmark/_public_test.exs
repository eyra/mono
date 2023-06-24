defmodule Systems.Benchmark.PublicTest do
  use Core.DataCase

  alias Systems.{
    Benchmark
  }

  test "import_csv_lines/1 one line" do
    %{id: toold_id} = tool = create_tool()
    %{name: name} = spot = create_spot(tool)
    %{id: submission_id, description: description} = create_submission(spot)

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

    {:ok, result} = Benchmark.Public.import_csv_lines([csv_line], tool.id)

    cat1_score_key = "#{cat1}-#{submission_id}"
    cat2_score_key = "#{cat2}-#{submission_id}"
    cat3_score_key = "#{cat3}-#{submission_id}"

    assert Enum.count(Map.keys(result)) == 7

    assert count_leaderboards() == 3
    assert count_scores() == 3

    assert %{
             {:leaderboard, ^cat1} => %Systems.Benchmark.LeaderboardModel{
               name: ^cat1,
               tool_id: ^toold_id
             },
             {:leaderboard, ^cat2} => %Systems.Benchmark.LeaderboardModel{
               name: ^cat2,
               tool_id: ^toold_id
             },
             {:leaderboard, ^cat3} => %Systems.Benchmark.LeaderboardModel{
               name: ^cat3,
               tool_id: ^toold_id
             },
             {:score, ^cat1_score_key} => %Systems.Benchmark.ScoreModel{
               score: ^cat1_score,
               submission_id: ^submission_id
             },
             {:score, ^cat2_score_key} => %Systems.Benchmark.ScoreModel{
               score: ^cat2_score,
               submission_id: ^submission_id
             },
             {:score, ^cat3_score_key} => %Systems.Benchmark.ScoreModel{
               score: ^cat3_score,
               submission_id: ^submission_id
             }
           } = result
  end

  test "import_csv_lines/1 one line with score `0`" do
    %{id: toold_id} = tool = create_tool()
    %{name: name} = spot = create_spot(tool)
    %{id: submission_id, description: description} = create_submission(spot)

    cat1 = "aap"

    csv_line = %{
      "id" => "#{submission_id}:#{name}:#{description}",
      "status" => "success",
      "error_message" => "",
      cat1 => "0"
    }

    {:ok, result} = Benchmark.Public.import_csv_lines([csv_line], tool.id)

    cat1_score_key = "#{cat1}-#{submission_id}"

    assert Enum.count(Map.keys(result)) == 3

    assert count_leaderboards() == 1
    assert count_scores() == 1

    assert %{
             {:leaderboard, ^cat1} => %Systems.Benchmark.LeaderboardModel{
               name: ^cat1,
               tool_id: ^toold_id
             },
             {:score, ^cat1_score_key} => %Systems.Benchmark.ScoreModel{
               score: 0.0,
               submission_id: ^submission_id
             }
           } = result
  end

  test "import_csv_lines/1 one line with empty score" do
    %{id: toold_id} = tool = create_tool()
    %{name: name} = spot = create_spot(tool)
    %{id: submission_id, description: description} = create_submission(spot)

    cat1 = "aap"

    csv_line = %{
      "id" => "#{submission_id}:#{name}:#{description}",
      "status" => "success",
      "error_message" => "",
      cat1 => ""
    }

    {:ok, result} = Benchmark.Public.import_csv_lines([csv_line], tool.id)

    cat1_score_key = "#{cat1}-#{submission_id}"

    assert Enum.count(Map.keys(result)) == 3

    assert count_leaderboards() == 1
    assert count_scores() == 1

    assert %{
             {:leaderboard, ^cat1} => %Systems.Benchmark.LeaderboardModel{
               name: ^cat1,
               tool_id: ^toold_id
             },
             {:score, ^cat1_score_key} => %Systems.Benchmark.ScoreModel{
               score: 0.0,
               submission_id: ^submission_id
             }
           } = result
  end

  test "import_csv_lines/1 two lines two submissions" do
    %{id: tool_id} = tool = create_tool()
    %{name: name} = spot = create_spot(tool)
    %{id: submission_id1, description: description1} = create_submission(spot, "Method X")
    %{id: submission_id2, description: description2} = create_submission(spot, "Method Y")

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

    {:ok, result} = Benchmark.Public.import_csv_lines([csv_line1, csv_line2], tool_id)

    assert Enum.count(Map.keys(result)) == 4

    assert count_leaderboards() == 1
    assert count_scores() == 2
  end

  test "import_csv_lines/1 two lines one submission should fail" do
    %{id: tool_id} = tool = create_tool()
    %{name: name} = spot = create_spot(tool)
    %{id: submission_id, description: description} = create_submission(spot, "Method X")

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
      Benchmark.Public.import_csv_lines([csv_line1, csv_line2], tool_id)
    end
  end

  test "import_csv_lines/1 ignore errors" do
    %{id: tool_id} = tool = create_tool()
    %{name: name} = spot = create_spot(tool)
    %{id: submission_id1, description: description1} = create_submission(spot, "Method X")
    %{id: submission_id2, description: description2} = create_submission(spot, "Method Y")

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

    {:ok, result} = Benchmark.Public.import_csv_lines([csv_line1, csv_line2], tool_id)

    assert Enum.count(Map.keys(result)) == 3
  end

  test "import_csv_lines/1 two version after two imports" do
    tool = create_tool()
    %{name: name} = spot = create_spot(tool)
    %{id: submission_id, description: description} = create_submission(spot)

    cat1 = "aap"

    csv_line = %{
      "id" => "#{submission_id}:#{name}:#{description}",
      "status" => "success",
      "error_message" => "",
      cat1 => ""
    }

    {:ok, %{version: version1}} = Benchmark.Public.import_csv_lines([csv_line], tool.id)
    {:ok, %{version: version2}} = Benchmark.Public.import_csv_lines([csv_line], tool.id)

    assert version1 < version2

    assert count_leaderboards() == 2
    assert count_scores() == 2
  end

  defp create_tool() do
    Factories.insert!(:benchmark_tool, %{status: :concept, director: :project})
  end

  defp create_spot(tool, name \\ "Team Eyra") do
    Factories.insert!(:benchmark_spot, %{tool: tool, name: name})
  end

  defp create_submission(spot, description \\ "Method X") do
    submission_attr = %{
      spot: spot,
      description: description,
      github_commit_url:
        "https://github.com/eyra/mono/commit/9d10bd2907dda135ebe86511489570dbf8c067c0"
    }

    Factories.insert!(:benchmark_submission, submission_attr)
  end

  defp count_scores() do
    Repo.one(
      Ecto.Query.from(
        score in Benchmark.ScoreModel,
        select: count(score.id)
      )
    )
  end

  defp count_leaderboards() do
    Repo.one(
      Ecto.Query.from(
        leaderboard in Benchmark.LeaderboardModel,
        select: count(leaderboard.id)
      )
    )
  end
end
