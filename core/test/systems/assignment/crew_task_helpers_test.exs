defmodule Systems.Assignment.CrewTaskHelpersTest do
  use ExUnit.Case, async: true

  alias Systems.Account.User
  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Workflow

  setup do
    %{
      assignment: %Assignment.Model{id: 20},
      user: %User{id: 10},
      workflow_item: %Workflow.ItemModel{id: 30, title: "Task & follow-up"},
      task: %Crew.TaskModel{id: 40, status: :pending}
    }
  end

  test "pending tasks check unfinished attempts; finished tasks clear previous attempts on entry",
       %{assignment: assignment, user: user, workflow_item: workflow_item, task: task} do
    pending = Assignment.CrewTaskHelpers.recovery_context(assignment, user, {workflow_item, task})
    assert pending.on_entry == :check

    for status <- [:completed, :accepted, :rejected] do
      finished =
        Assignment.CrewTaskHelpers.recovery_context(
          assignment,
          user,
          {workflow_item, %{task | status: status}}
        )

      assert finished.on_entry == :clear_previous
      assert finished.scope == pending.scope
    end
  end

  test "attempt scope preserves the marker format and isolates users, assignments, and tasks",
       %{assignment: assignment, user: user, workflow_item: workflow_item, task: task} do
    context = Assignment.CrewTaskHelpers.recovery_context(assignment, user, {workflow_item, task})
    assert context.scope == "10:20:40"

    for {other_assignment, other_user, other_task} <- [
          {assignment, %{user | id: 11}, task},
          {%{assignment | id: 21}, user, task},
          {assignment, user, %{task | id: 41}}
        ] do
      other_context =
        Assignment.CrewTaskHelpers.recovery_context(
          other_assignment,
          other_user,
          {workflow_item, other_task}
        )

      refute other_context.scope == context.scope
    end
  end

  test "support link opens an email that identifies the affected task",
       %{assignment: assignment, user: user, workflow_item: workflow_item, task: task} do
    context = Assignment.CrewTaskHelpers.recovery_context(assignment, user, {workflow_item, task})
    uri = URI.parse(context.support_url)

    assert uri.scheme == "mailto"
    assert uri.path == "support@eyra.co"

    body = URI.decode_query(uri.query)["body"]
    assert body =~ "Task & follow-up"
    assert body =~ "assignment_id: 20"
    assert body =~ "task_id: 40"
  end
end
