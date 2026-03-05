defmodule Systems.Graphite.PublicTest do
  use Core.DataCase

  alias CoreWeb.UI.Timestamp
  alias Systems.Graphite
  alias Systems.Graphite.Factories
  alias Systems.Graphite.SubmissionModel

  describe "open_for_submissions?/1" do
    test "no deadline" do
      tool = Core.Factories.insert!(:graphite_tool)
      assert Graphite.Public.open_for_submissions?(tool)
    end

    test "deadline tomorrow" do
      deadline = DateTime.truncate(Timestamp.tomorrow(), :second)
      tool = Core.Factories.insert!(:graphite_tool, %{deadline: deadline})
      assert Graphite.Public.open_for_submissions?(tool)
    end

    test "deadline yesterday" do
      deadline = DateTime.truncate(Timestamp.yesterday(), :second)
      tool = Core.Factories.insert!(:graphite_tool, %{deadline: deadline})
      refute Graphite.Public.open_for_submissions?(tool)
    end

    test "deadline one minute ago" do
      deadline = Timestamp.now() |> Timestamp.shift_minutes(-1) |> DateTime.truncate(:second)
      tool = Core.Factories.insert!(:graphite_tool, %{deadline: deadline})
      refute Graphite.Public.open_for_submissions?(tool)
    end

    test "deadline in one minute" do
      deadline = Timestamp.now() |> Timestamp.shift_minutes(1) |> DateTime.truncate(:second)
      tool = Core.Factories.insert!(:graphite_tool, %{deadline: deadline})
      assert Graphite.Public.open_for_submissions?(tool)
    end

    test "deadline now" do
      deadline = DateTime.truncate(Timestamp.now(), :second)
      tool = Core.Factories.insert!(:graphite_tool, %{deadline: deadline})
      refute Graphite.Public.open_for_submissions?(tool)
    end
  end

  describe "can_update?/1" do
    test "no deadline" do
      tool = Core.Factories.insert!(:graphite_tool)
      submission = Factories.add_submission(tool)
      assert Graphite.Public.can_update?(submission)
    end

    test "deadline in one minute" do
      deadline = Timestamp.now() |> Timestamp.shift_minutes(1) |> DateTime.truncate(:second)
      tool = Core.Factories.insert!(:graphite_tool, %{deadline: deadline})
      submission = Factories.add_submission(tool)
      assert Graphite.Public.can_update?(submission)
    end

    test "deadline one minute ago" do
      deadline = Timestamp.now() |> Timestamp.shift_minutes(-1) |> DateTime.truncate(:second)
      tool = Core.Factories.insert!(:graphite_tool, %{deadline: deadline})
      submission = Factories.add_submission(tool)
      refute Graphite.Public.can_update?(submission)
    end

    test "deadline now" do
      deadline = DateTime.truncate(Timestamp.now(), :second)
      tool = Core.Factories.insert!(:graphite_tool, %{deadline: deadline})
      submission = Factories.add_submission(tool)
      refute Graphite.Public.can_update?(submission)
    end
  end

  describe "list_submissions/1" do
    test "no submissions" do
      tool = Core.Factories.insert!(:graphite_tool)
      assert [] = Graphite.Public.list_submissions(tool)
    end

    test "one submission" do
      tool = %{id: tool_id} = Core.Factories.insert!(:graphite_tool)
      %{id: submission_id} = Factories.add_submission(tool)

      assert [
               %SubmissionModel{id: ^submission_id, tool_id: ^tool_id}
             ] = Graphite.Public.list_submissions(tool)
    end

    test "multiple submissions" do
      tool = %{id: tool_id} = Core.Factories.insert!(:graphite_tool)
      %{id: submission1_id} = Factories.add_submission(tool)
      %{id: submission2_id} = Factories.add_submission(tool)
      %{id: submission3_id} = Factories.add_submission(tool)

      assert [
               %SubmissionModel{id: ^submission1_id, tool_id: ^tool_id},
               %SubmissionModel{id: ^submission2_id, tool_id: ^tool_id},
               %SubmissionModel{id: ^submission3_id, tool_id: ^tool_id}
             ] = Graphite.Public.list_submissions(tool)
    end
  end
end
