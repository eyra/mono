defmodule Systems.Graphite.PublicTest do
  use Core.DataCase

  alias Systems.Graphite
  alias Systems.Graphite.Factories

  describe "list_submissions/1" do
    test "no submissions" do
      tool = Core.Factories.insert!(:graphite_tool)
      assert [] = Graphite.Public.list_submissions(tool)
    end

    test "one submission" do
      tool = %{id: tool_id} = Core.Factories.insert!(:graphite_tool)
      %{id: submission_id} = Factories.add_submission(tool)

      assert [
               %Systems.Graphite.SubmissionModel{id: ^submission_id, tool_id: ^tool_id}
             ] = Graphite.Public.list_submissions(tool)
    end

    test "multiple submissions" do
      tool = %{id: tool_id} = Core.Factories.insert!(:graphite_tool)
      %{id: submission1_id} = Factories.add_submission(tool)
      %{id: submission2_id} = Factories.add_submission(tool)
      %{id: submission3_id} = Factories.add_submission(tool)

      assert [
               %Systems.Graphite.SubmissionModel{id: ^submission1_id, tool_id: ^tool_id},
               %Systems.Graphite.SubmissionModel{id: ^submission2_id, tool_id: ^tool_id},
               %Systems.Graphite.SubmissionModel{id: ^submission3_id, tool_id: ^tool_id}
             ] = Graphite.Public.list_submissions(tool)
    end
  end
end
