defmodule Systems.Benchmark.ExportControllerTest do
  use Core.DataCase

  alias Systems.{
    Benchmark
  }

  test "export/1 with valid submission" do
    tool = Factories.insert!(:benchmark_tool, %{status: :concept, director: :project})
    spot = Factories.insert!(:benchmark_spot, %{tool: tool, name: "Team Eyra"})

    %{id: id} =
      submission =
      Factories.insert!(:benchmark_submission, %{
        spot: spot,
        description: "description",
        github_commit_url:
          "https://github.com/eyra/mono/commit/5405deccef0aa1a594cc09da99185860bc3e0cd2"
      })

    expected_id = "#{id}:#{spot.name}:#{submission.description}"

    assert %{
             id: ^expected_id,
             url: "git@github.com:eyra/mono.git",
             ref: "5405deccef0aa1a594cc09da99185860bc3e0cd2"
           } = Benchmark.ExportController.export(submission)
  end

  test "export/1 with invalid submission" do
    tool = Factories.insert!(:benchmark_tool, %{status: :concept, director: :project})
    spot = Factories.insert!(:benchmark_spot, %{tool: tool, name: "Team Eyra"})

    %{id: id} =
      submission =
      Factories.insert!(:benchmark_submission, %{
        spot: spot,
        description: "description",
        github_commit_url:
          "https://github.com/eyra/mono/commit/5405deccef0aa1a594cc09da99185860bc3e0cd"
      })

    expected_id = "#{id}:#{spot.name}:#{submission.description}"

    assert %{
             id: ^expected_id,
             url: "https://github.com/eyra/mono/commit/5405deccef0aa1a594cc09da99185860bc3e0cd",
             ref: ""
           } = Benchmark.ExportController.export(submission)
  end
end
