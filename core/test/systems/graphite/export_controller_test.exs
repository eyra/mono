defmodule Systems.Graphite.ExportControllerTest do
  use Core.DataCase

  alias Systems.{
    Graphite
  }

  test "export/1 with valid submission" do
    tool = Factories.insert!(:graphite_tool, %{})

    %{id: id} =
      submission =
      Factories.insert!(:graphite_submission, %{
        tool: tool,
        description: "description",
        github_commit_url:
          "https://github.com/eyra/mono/commit/5405deccef0aa1a594cc09da99185860bc3e0cd2"
      })

    expected_id = "#{id}"

    assert %{
             "submission-id" => ^expected_id,
             "url" => "git@github.com:eyra/mono.git",
             "ref" => "5405deccef0aa1a594cc09da99185860bc3e0cd2"
           } = Graphite.ExportController.export(submission)
  end

  test "export/1 valid with pull request commit" do
    tool = Factories.insert!(:graphite_tool, %{})

    %{id: id} =
      submission =
      Factories.insert!(:graphite_submission, %{
        tool: tool,
        description: "description",
        github_commit_url:
          "https://github.com/eyra/mono/pull/717/commits/119d6db9138837e63d102ba39d157e986066fba3"
      })

    expected_id = "#{id}"

    assert %{
             "submission-id" => ^expected_id,
             "url" => "git@github.com:eyra/mono.git",
             "ref" => "119d6db9138837e63d102ba39d157e986066fba3"
           } = Graphite.ExportController.export(submission)
  end

  test "export/1 with invalid submission" do
    tool = Factories.insert!(:graphite_tool, %{})

    %{id: id} =
      submission =
      Factories.insert!(:graphite_submission, %{
        tool: tool,
        description: "description",
        github_commit_url:
          "https://github.com/eyra/mono/commit/5405deccef0aa1a594cc09da99185860bc3e0cd"
      })

    expected_id = "#{id}"

    assert %{
             "submission-id" => ^expected_id,
             "url" =>
               "https://github.com/eyra/mono/commit/5405deccef0aa1a594cc09da99185860bc3e0cd",
             "ref" => ""
           } = Graphite.ExportController.export(submission)
  end
end
