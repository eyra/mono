defmodule Systems.Assignment.CrewTaskHorizontalListViewTest do
  use MicaWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Systems.Assignment
  alias Systems.Crew

  @current_step "[data-testid='step-progress-step'][aria-current='step']"
  @intro "[data-testid='task-intro']"

  # Tests tagged :signals keep the real signal handlers, so a task completed outside the
  # view reaches it through the Switch and the Observatory
  setup %{conn: conn} = tags do
    unless tags[:signals], do: isolate_signals()

    user = Factories.insert!(:member)
    assignment = Assignment.Factories.create_assignment_with_multiple_tasks()
    assignment = Assignment.Factories.add_participant(assignment, user)
    conn = Map.put(conn, :request_path, "/assignment/tasks")

    %{conn: conn, user: user, assignment: assignment}
  end

  test "shows one step per task and the first task's intro", %{
    conn: conn,
    user: user,
    assignment: assignment
  } do
    view = mount_view(conn, user, assignment)

    assert view
           |> render()
           |> Floki.parse_document!()
           |> Floki.find("[data-testid='step-progress-step']")
           |> length() == 2

    assert view |> element(@current_step) |> render() =~ "Task 1 of 2"
    assert has_element?(view, @intro, "Task 1")
    assert has_element?(view, "#{@intro} [data-testid='task-intro-start']")
  end

  test "has no done button", %{conn: conn, user: user, assignment: assignment} do
    view = mount_view(conn, user, assignment)

    refute has_element?(view, "[phx-click='done']")
  end

  test "opens no tool before the participant starts the task", %{
    conn: conn,
    user: user,
    assignment: assignment
  } do
    view = mount_view(conn, user, assignment)

    assert %{tool_modal: nil} = assigns(view)
    assert [%{started_at: nil}, %{started_at: nil}] = tasks(assignment, user)
  end

  test "starting the task opens its tool in the full-screen modal", %{
    conn: conn,
    user: user,
    assignment: assignment
  } do
    view = mount_view(conn, user, assignment)

    render_click(view, "start_task")

    assert %{tool_modal: %{style: :full, element: %{id: "tool_modal"}}} = assigns(view)
    assert [%{started_at: %NaiveDateTime{}}, %{started_at: nil}] = tasks(assignment, user)
  end

  test "closing the modal brings the participant back to the task's intro", %{
    conn: conn,
    user: user,
    assignment: assignment
  } do
    view = mount_view(conn, user, assignment)
    render_click(view, "start_task")

    send(
      view.pid,
      {:live_nest_event, %LiveNest.Event{name: :modal_closed, payload: %{modal_id: "tool_modal"}}}
    )

    assert %{tool_modal: nil} = assigns(view)
    assert has_element?(view, @intro, "Task 1")
    assert [%{status: :pending}, %{status: :pending}] = tasks(assignment, user)
  end

  test "a finished task moves the list to the next task's intro", %{
    conn: conn,
    user: user,
    assignment: assignment
  } do
    view = mount_view(conn, user, assignment)
    :erlang.trace(view.pid, true, [:receive])

    complete_tool(view)

    assert [%{status: :completed}, %{status: :pending}] = tasks(assignment, user)
    assert %{tool_modal: nil} = assigns(view)
    assert view |> element(@current_step) |> render() =~ "Task 2 of 2"
    assert has_element?(view, @intro, "Task 2")
    refute_received {:trace, _, :receive, {:live_nest_event, %LiveNest.Event{name: :work_done}}}
  end

  # E.g. a double click on a manual's Done, or an app exiting after its task was
  # completed on another device: only the task whose tool was open completes
  test "a second completion from the same tool doesn't complete the next task", %{
    conn: conn,
    user: user,
    assignment: assignment
  } do
    view = mount_view(conn, user, assignment)
    :erlang.trace(view.pid, true, [:receive])

    render_click(view, "start_task")
    send(view.pid, {:live_nest_event, %LiveNest.Event{name: :tool_completed, payload: %{}}})
    send(view.pid, {:live_nest_event, %LiveNest.Event{name: :tool_completed, payload: %{}}})
    render(view)

    assert [%{status: :completed}, %{status: :pending}] = tasks(assignment, user)
    assert has_element?(view, @intro, "Task 2")
    refute_received {:trace, _, :receive, {:live_nest_event, %LiveNest.Event{name: :work_done}}}
  end

  test "the next task's intro shows its own number", %{
    conn: conn,
    user: user,
    assignment: assignment
  } do
    view = mount_view(conn, user, assignment)

    complete_tool(view)

    assert view |> element("#{@intro} [data-testid='step-number']") |> render() =~ ~r/>\s*2\s*</
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
    assignment: assignment
  } do
    {:ok, _} = assignment |> tasks(user) |> List.first() |> Crew.Public.complete_task()

    view = mount_view(conn, user, assignment)

    assert view |> element(@current_step) |> render() =~ "Task 2 of 2"
    assert has_element?(view, @intro, "Task 2")
  end

  @tag :signals
  test "a task completed outside the view moves the list to the next task", %{
    conn: conn,
    user: user,
    assignment: assignment
  } do
    view = mount_view(conn, user, assignment)

    # Completed the way a questionnaire callback or another device completes it
    {:ok, _} = assignment |> tasks(user) |> List.first() |> Crew.Public.complete_task()

    assert eventually(fn -> has_element?(view, @intro, "Task 2") end)
    assert view |> element(@current_step) |> render() =~ "Task 2 of 2"
  end

  @tag :signals
  test "a tool that completes after its task finished elsewhere doesn't complete the next task",
       %{conn: conn, user: user, assignment: assignment} do
    view = mount_view(conn, user, assignment)
    render_click(view, "start_task")

    {:ok, _} = assignment |> tasks(user) |> List.first() |> Crew.Public.complete_task()
    assert eventually(fn -> has_element?(view, @intro, "Task 2") end)

    send(view.pid, {:live_nest_event, %LiveNest.Event{name: :tool_completed, payload: %{}}})
    render(view)

    assert [%{status: :completed}, %{status: :pending}] = tasks(assignment, user)
  end

  @tag :signals
  test "participation finishes when the last task completes outside the view", %{
    conn: conn,
    user: user,
    assignment: assignment
  } do
    view = mount_view(conn, user, assignment)
    :erlang.trace(view.pid, true, [:receive])
    complete_tool(view)

    {:ok, _} = assignment |> tasks(user) |> List.last() |> Crew.Public.complete_task()

    assert_receive {:trace, _, :receive, {:live_nest_event, %LiveNest.Event{name: :work_done}}},
                   1000
  end

  @tag :signals
  test "participation finishes once when the last tool completes and its signal follows", %{
    conn: conn,
    user: user,
    assignment: assignment
  } do
    view = mount_view(conn, user, assignment)
    :erlang.trace(view.pid, true, [:receive])

    complete_tool(view)
    complete_tool(view)
    Process.sleep(300)
    render(view)

    assert_received {:trace, _, :receive, {:live_nest_event, %LiveNest.Event{name: :work_done}}}
    refute_received {:trace, _, :receive, {:live_nest_event, %LiveNest.Event{name: :work_done}}}
  end

  defp eventually(fun, attempts \\ 20) do
    cond do
      fun.() -> true
      attempts == 0 -> false
      true -> Process.sleep(50) && eventually(fun, attempts - 1)
    end
  end

  # The participant starts the current task and its tool reports completion
  defp complete_tool(view) do
    render_click(view, "start_task")
    send(view.pid, {:live_nest_event, %LiveNest.Event{name: :tool_completed, payload: %{}}})
    render(view)
  end

  defp assigns(view), do: :sys.get_state(view.pid).socket.assigns

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
        user_state: %{},
        panel_info: nil
      })

    {:ok, view, _html} =
      live_isolated(conn, Assignment.CrewTaskHorizontalListView,
        session: %{"live_context" => live_context}
      )

    view
  end
end
