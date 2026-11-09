defmodule Systems.Assignment.CrewTaskHorizontalListViewTest do
  use MicaWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Systems.Assignment
  alias Systems.Crew
  alias Systems.Workflow

  @current_step "[data-testid='step-progress-step'][aria-current='step']"

  setup %{conn: conn} do
    isolate_signals()

    user = Factories.insert!(:member)
    assignment = Assignment.Factories.create_assignment_with_multiple_tasks()
    assignment = Assignment.Factories.add_participant(assignment, user)
    [first, second] = Workflow.Model.ordered_items(assignment.workflow)
    conn = Map.put(conn, :request_path, "/assignment/tasks")

    %{conn: conn, user: user, assignment: assignment, first: first, second: second}
  end

  test "shows one step per task and the first task's start view", %{
    conn: conn,
    user: user,
    assignment: assignment,
    first: first
  } do
    view = mount_view(conn, user, assignment)

    assert view
           |> render()
           |> Floki.parse_document!()
           |> Floki.find("[data-testid='step-progress-step']")
           |> length() == 2

    assert view |> element(@current_step) |> render() =~ "Task 1 of 2"
    assert has_element?(view, "##{tool_view_id(first)}")
  end

  test "has no done button", %{conn: conn, user: user, assignment: assignment} do
    view = mount_view(conn, user, assignment)

    refute has_element?(view, "[phx-click='done']")
  end

  test "starts the current task", %{conn: conn, user: user, assignment: assignment} do
    mount_view(conn, user, assignment)

    assert [%{started_at: %NaiveDateTime{}}, %{started_at: nil}] = tasks(assignment, user)
  end

  test "a finished task moves the list to the next task", %{
    conn: conn,
    user: user,
    assignment: assignment,
    second: second
  } do
    view = mount_view(conn, user, assignment)
    :erlang.trace(view.pid, true, [:receive])

    complete_tool(view)

    assert [%{status: :completed}, %{status: :pending, started_at: %NaiveDateTime{}}] =
             tasks(assignment, user)

    assert view |> element(@current_step) |> render() =~ "Task 2 of 2"
    assert has_element?(view, "##{tool_view_id(second)}")
    refute_received {:trace, _, :receive, {:live_nest_event, %LiveNest.Event{name: :work_done}}}
  end

  test "participation finishes after the last task", %{
    conn: conn,
    user: user,
    assignment: assignment
  } do
    view = mount_view(conn, user, assignment)
    :erlang.trace(view.pid, true, [:receive])

    complete_tool(view)
    complete_tool(view)

    assert [%{status: :completed}, %{status: :completed}] = tasks(assignment, user)
    assert_receive {:trace, _, :receive, {:live_nest_event, %LiveNest.Event{name: :work_done}}}
  end

  test "coming back lands on the first unfinished task", %{
    conn: conn,
    user: user,
    assignment: assignment,
    second: second
  } do
    {:ok, _} = assignment |> tasks(user) |> List.first() |> Crew.Public.complete_task()

    view = mount_view(conn, user, assignment)

    assert view |> element(@current_step) |> render() =~ "Task 2 of 2"
    assert has_element?(view, "##{tool_view_id(second)}")
  end

  defp complete_tool(view) do
    send(view.pid, {:live_nest_event, %LiveNest.Event{name: :tool_completed, payload: %{}}})
    render(view)
  end

  defp tool_view_id(%{id: id}), do: "tool_view_#{id}"

  defp tasks(assignment, user) do
    assignment
    |> Assignment.CrewTaskHelpers.build_work_items(user)
    |> Enum.map(fn {_item, task} -> task end)
  end

  defp mount_view(conn, user, assignment) do
    live_context =
      Frameworks.Concept.LiveContext.new(%{
        assignment_id: assignment.id,
        current_user: user,
        panel_info: nil
      })

    {:ok, view, _html} =
      live_isolated(conn, Assignment.CrewTaskHorizontalListView,
        session: %{"live_context" => live_context}
      )

    view
  end
end
