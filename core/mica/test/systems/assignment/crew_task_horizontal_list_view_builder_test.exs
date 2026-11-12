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
             %{id: first_id, number: 1, status: :current, label: "Task 1 of 2"},
             %{id: second_id, number: 2, status: :incomplete, label: "Task 2 of 2"}
           ] = vm.steps

    assert {first_id, second_id} == {first.id, second.id}
    assert {%{id: ^first_id}, _task} = vm.work_item
  end

  test "the intro shows the current task's number, title and start button", %{
    user: user,
    assignment: assignment
  } do
    assert %{
             intro: %{
               number: 1,
               title: "Task 1",
               button: %{action: %{type: :send, event: "start_task"}}
             }
           } = view_model(assignment, user)
  end

  test "the intro shows the researcher's description of the task", %{
    user: user,
    assignment: assignment,
    first: first
  } do
    first |> Ecto.Changeset.change(description: "Listen to a short story.") |> Repo.update!()
    assignment = Repo.preload(assignment, Assignment.Model.preload_graph(:down), force: true)

    assert %{intro: %{description: "Listen to a short story."}} = view_model(assignment, user)
  end

  test "no tool before the participant starts the current task", %{
    user: user,
    assignment: assignment
  } do
    assert %{tool_modal: nil} = view_model(assignment, user)
  end

  test "the started task's tool opens in the full-screen modal and starts at once", %{
    user: user,
    assignment: assignment,
    first: %{id: first_id}
  } do
    %{tool_modal: tool_modal} = view_model(assignment, user, %{task: first_id})

    assert %{style: :full, element: %{id: "tool_modal", options: options}} = tool_modal

    assert %{presentation: :modal, autostart: true, workflow_item_id: ^first_id} =
             options[:live_context].data
  end

  test "no tool for a started task that isn't current any more", %{
    user: user,
    assignment: assignment,
    first: %{id: first_id}
  } do
    complete_task(assignment, user, 0)

    assert %{tool_modal: nil} = view_model(assignment, user, %{task: first_id})
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
    assert %{number: 2, title: "Task 2"} = vm.intro
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
    assert vm.intro == nil
  end

  test "finished after the last task", %{user: user, assignment: assignment} do
    complete_task(assignment, user, 0)
    complete_task(assignment, user, 1)

    assert %{finished?: true} = view_model(assignment, user)
  end

  test "not finished while a task is left", %{user: user, assignment: assignment} do
    complete_task(assignment, user, 0)

    assert %{finished?: false} = view_model(assignment, user)
  end

  # The required tasks decide, as everywhere else (Assignment.Public.required_tasks_finished?)
  test "finished once the required tasks are, with an optional task left", %{
    user: user,
    assignment: assignment,
    second: second
  } do
    second |> Ecto.Changeset.change(required: false) |> Repo.update!()
    assignment = Repo.preload(assignment, Assignment.Model.preload_graph(:down), force: true)
    complete_task(assignment, user, 0)

    assert %{finished?: true} = view_model(assignment, user)
  end

  test "not finished without tasks for the user", %{assignment: assignment} do
    other_user = Factories.insert!(:member)

    assert %{steps: [], finished?: false} = view_model(assignment, other_user)
  end

  defp complete_task(assignment, user, index) do
    {:ok, _} = assignment |> tasks(user) |> Enum.at(index) |> Crew.Public.complete_task()
  end

  defp tasks(assignment, user) do
    assignment
    |> Assignment.CrewTaskHelpers.build_work_items(user)
    |> Enum.map(fn {_item, task} -> task end)
  end

  defp view_model(assignment, user, user_state \\ %{}) do
    live_context =
      Frameworks.Concept.LiveContext.new(%{
        current_user: user,
        timezone: "UTC",
        user_state: user_state,
        panel_info: nil
      })

    Assignment.CrewTaskHorizontalListViewBuilder.view_model(assignment, %{
      assignment_id: assignment.id,
      current_user: user,
      user_state: user_state,
      live_context: live_context
    })
  end
end
