defmodule Systems.Assignment.CrewTaskHorizontalListViewBuilderTest do
  use Mica.DataCase

  alias Mica.Repo
  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Workflow

  setup do
    user = Factories.insert!(:member)
    assignment = Assignment.Factories.create_assignment_with_multiple_tasks()
    assignment = Assignment.Factories.add_participant(assignment, user)
    assignment = Repo.preload(assignment, Assignment.Model.preload_graph(:down), force: true)
    [first, second] = Workflow.Model.ordered_items(assignment.workflow)

    %{user: user, assignment: assignment, first: first, second: second}
  end

  test "one step per task in workflow order, the first one current", %{
    user: user,
    assignment: assignment,
    first: first,
    second: second
  } do
    vm = view_model(assignment, user)

    assert [
             %{id: first_id, status: :current, label: "Task 1 of 2"},
             %{id: second_id, status: :incomplete, label: "Task 2 of 2"}
           ] = vm.steps

    assert {first_id, second_id} == {first.id, second.id}
    assert {%{id: ^first_id}, _task} = vm.work_item
  end

  test "loads the current task's start view on the page, one view per task", %{
    user: user,
    assignment: assignment,
    first: %{id: first_id}
  } do
    %{tool_view: tool_view} = view_model(assignment, user)

    assert tool_view.id == "tool_view_#{first_id}"

    assert %{presentation: :start_on_page, workflow_item_id: ^first_id} =
             tool_view.options[:live_context].data
  end

  test "lands on the first unfinished task", %{
    user: user,
    assignment: assignment,
    second: %{id: second_id}
  } do
    complete_task(assignment, user, 0)

    vm = view_model(assignment, user)

    assert [%{status: :complete}, %{status: :current}] = vm.steps
    assert {%{id: ^second_id}, _task} = vm.work_item
    assert vm.tool_view.id == "tool_view_#{second_id}"
  end

  test "an earlier unfinished task comes before a later finished one", %{
    user: user,
    assignment: assignment,
    first: %{id: first_id}
  } do
    complete_task(assignment, user, 1)

    vm = view_model(assignment, user)

    assert [%{status: :current}, %{status: :incomplete}] = vm.steps
    assert {%{id: ^first_id}, _task} = vm.work_item
  end

  test "no current task after the last one", %{user: user, assignment: assignment} do
    complete_task(assignment, user, 0)
    complete_task(assignment, user, 1)

    vm = view_model(assignment, user)

    assert [%{status: :complete}, %{status: :complete}] = vm.steps
    assert vm.work_item == nil
    assert vm.tool_view == nil
  end

  defp complete_task(assignment, user, index) do
    {:ok, _} = assignment |> tasks(user) |> Enum.at(index) |> Crew.Public.complete_task()
  end

  defp tasks(assignment, user) do
    assignment
    |> Assignment.CrewTaskHelpers.build_work_items(user)
    |> Enum.map(fn {_item, task} -> task end)
  end

  defp view_model(assignment, user) do
    live_context =
      Frameworks.Concept.LiveContext.new(%{
        current_user: user,
        timezone: "UTC",
        panel_info: nil
      })

    Assignment.CrewTaskHorizontalListViewBuilder.view_model(assignment, %{
      assignment_id: assignment.id,
      current_user: user,
      live_context: live_context
    })
  end
end
