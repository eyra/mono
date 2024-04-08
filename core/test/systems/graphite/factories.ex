defmodule Systems.Graphite.Factories do
  alias Core.Factories
  alias Systems.Graphite
  alias Systems.Workflow
  alias Systems.Assignment

  def create_tool() do
    Factories.insert!(:graphite_tool, %{})
  end

  def create_leaderboard(%Graphite.ToolModel{} = tool) do
    Factories.insert!(:graphite_leaderboard, %{tool: tool})
  end

  def create_challenge() do
    Factories.insert!(:assignment, %{special: :benchmark_challenge})
  end

  def add_tool(%Assignment.Model{workflow: workflow}) do
    tool = Factories.insert!(:graphite_tool)
    tool_ref = Workflow.Factories.create_tool_ref(tool, :submit)
    Workflow.Factories.create_item(workflow, tool_ref, 0)

    tool
  end

  def add_submission(%Graphite.ToolModel{} = tool) do
    Factories.insert!(:graphite_submission, %{
      tool: tool,
      description: "description",
      github_commit_url:
        "https://github.com/org/repo/commit/4cf8a66bcbe349488fabc211e1bfb72007a9f14a"
    })
  end

  def create_submission(tool, description \\ "Method X") do
    submission_attr = %{
      tool: tool,
      description: description,
      github_commit_url:
        "https://github.com/eyra/mono/commit/9d10bd2907dda135ebe86511489570dbf8c067c0"
    }

    Factories.insert!(:graphite_submission, submission_attr)
  end
end
