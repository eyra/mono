defmodule Systems.Feldspar.ToolViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Frameworks.Concept.LiveContext
  alias Systems.{Crew, Feldspar, Workflow}

  setup %{conn: conn} do
    isolate_signals()
    tool = Factories.insert!(:feldspar_tool, %{archive_ref: "https://example.com/app"})
    tool_ref = Factories.insert!(:tool_ref, %{feldspar_tool: tool})
    tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))
    user = Factories.insert!(:member)
    crew = Factories.insert!(:crew)
    {:ok, task} = Crew.Public.create_task(crew, user, [Ecto.UUID.generate()])

    context =
      LiveContext.new(%{
        title: "Test Feldspar App",
        icon: "TikTok",
        tool_ref: tool_ref,
        assignment_id: 123,
        participant: "test_participant",
        workflow_item_id: 456,
        current_user: user,
        task_id: task.id,
        task_status: task.status
      })

    modal = LiveNest.Modal.prepare_live_view("feldspar-tool", Feldspar.ToolView)

    {:ok, view, _html} =
      live_isolated(
        Map.put(conn, :request_path, "/feldspar/tool"),
        Feldspar.ToolView,
        session: %{"live_context" => context, "live_nest" => %{modal: modal}}
      )

    %{view: view, task: task}
  end

  test "does not mount an iframe until checking recovery and explicitly starting", %{view: view} do
    refute has_element?(view, "iframe")
    refute has_element?(view, "[phx-click='prepare_start']")
    assert has_element?(view, "img[src*='tiktok_square.svg']")

    render_click(view, "start", %{attempt_id: Ecto.UUID.generate()})
    refute has_element?(view, "iframe")

    render_hook(view, "feldspar_recovery_checked", %{unfinished: false})
    assert has_element?(view, "[phx-click='prepare_start']")
    refute has_element?(view, "iframe")

    render_click(view, "prepare_start")
    refute has_element?(view, "iframe")
    attempt_id = Ecto.UUID.generate()
    render_hook(view, "start", %{attempt_id: attempt_id})
    assert has_element?(view, "iframe")

    render_hook(view, "feldspar_event", %{
      __type__: "CommandSystemEvent",
      attempt_id: attempt_id,
      name: "initialized"
    })

    assert has_element?(view, "[data-testid='app-container'].block")
    assert has_element?(view, "[data-testid='start-container'].hidden")
  end

  test "an unfinished attempt offers support without starting another attempt", %{
    view: view,
    task: task
  } do
    render_hook(view, "feldspar_recovery_checked", %{unfinished: true})
    assert has_element?(view, "[data-testid='feldspar-recovery']")
    assert has_element?(view, "[phx-click='prepare_start']")

    assert has_element?(
             view,
             "a[data-testid='feldspar-recovery-support'][href='/support/helpdesk?assignment_id=123&task_id=#{task.id}']"
           )

    refute has_element?(view, "iframe")
    assert Repo.get!(Crew.TaskModel, task.id).status == :pending

    render_click(view, "prepare_start")
    render_hook(view, "start", %{attempt_id: Ecto.UUID.generate()})
    refute has_element?(view, "[data-testid='feldspar-recovery']")
    assert has_element?(view, "iframe")
  end

  test "server completion takes precedence over a stale browser marker", %{view: view, task: task} do
    task |> Ecto.Changeset.change(status: :completed) |> Repo.update!()
    render_hook(view, "feldspar_recovery_checked", %{unfinished: true})

    assert has_element?(view, "[data-completed='true']")
    refute has_element?(view, "[data-testid='feldspar-recovery']")
    refute has_element?(view, "[phx-click='prepare_start']")
    render_click(view, "prepare_start")
    render_hook(view, "start", %{attempt_id: Ecto.UUID.generate()})
    refute has_element?(view, "iframe")
  end

  test "completion in another tab during preparation prevents a retry", %{view: view, task: task} do
    render_hook(view, "feldspar_recovery_checked", %{unfinished: true})
    render_click(view, "prepare_start")
    task |> Ecto.Changeset.change(status: :completed) |> Repo.update!()
    render_hook(view, "start", %{attempt_id: Ecto.UUID.generate()})

    assert has_element?(view, "[data-completed='true']")
    refute has_element?(view, "iframe")
    refute has_element?(view, "[data-testid='feldspar-recovery']")
  end

  test "an unresponsive attempt offers the existing recovery actions until explicit retry", %{
    view: view,
    task: task
  } do
    attempt_id = start_attempt(view)
    initialize_attempt(view, attempt_id)
    assert_receive {:live_nest_event, %{name: :tool_initialized}}

    render_hook(view, "feldspar_unresponsive", %{attempt_id: attempt_id})

    assert has_element?(view, "[data-testid='feldspar-recovery']")
    assert has_element?(view, "[phx-click='prepare_start']")
    assert has_element?(view, "[data-testid='start-container'].flex")

    assert has_element?(
             view,
             "a[data-testid='feldspar-recovery-support'][href='/support/helpdesk?assignment_id=123&task_id=#{task.id}']"
           )

    refute has_element?(view, "iframe")
    refute_receive {:live_nest_event, %{name: :tool_completed}}
    assert Repo.get!(Crew.TaskModel, task.id).status == :pending
    assert Repo.get!(Crew.TaskModel, task.id).updated_at == task.updated_at

    render_hook(view, "start", %{attempt_id: Ecto.UUID.generate()})
    refute has_element?(view, "iframe")

    render_click(view, "prepare_start")
    refute has_element?(view, "iframe")
    retry_id = Ecto.UUID.generate()
    render_hook(view, "start", %{attempt_id: retry_id})

    refute has_element?(view, "[data-testid='feldspar-recovery']")
    assert has_element?(view, "[data-attempt-id='#{retry_id}'] iframe")
    refute has_element?(view, "[data-testid='app-container'].block")
  end

  test "late previous-attempt events cannot initialize, finish or interrupt a retry", %{
    view: view
  } do
    previous_id = start_attempt(view)
    render_hook(view, "feldspar_unresponsive", %{attempt_id: previous_id})
    render_click(view, "prepare_start")
    render_hook(view, "feldspar_unresponsive", %{attempt_id: previous_id})

    attempt_id = Ecto.UUID.generate()
    render_hook(view, "start", %{attempt_id: attempt_id})
    render_hook(view, "feldspar_unresponsive", %{attempt_id: previous_id})
    initialize_attempt(view, previous_id)
    exit_attempt(view, previous_id)
    render_hook(view, "feldspar_event", %{__type__: "CommandSystemEvent", name: "initialized"})
    render_hook(view, "feldspar_event", %{__type__: "CommandSystemExit", code: 0, info: ""})

    refute has_element?(view, "[data-testid='feldspar-recovery']")
    refute has_element?(view, "[data-testid='app-container'].block")
    assert has_element?(view, "[data-attempt-id='#{attempt_id}'] iframe")
    refute_receive {:live_nest_event, %{name: :tool_initialized}}
    refute_receive {:live_nest_event, %{name: :tool_completed}}

    initialize_attempt(view, attempt_id)
    assert has_element?(view, "[data-testid='app-container'].block")
    assert_receive {:live_nest_event, %{name: :tool_initialized}}
    initialize_attempt(view, attempt_id)
    refute_receive {:live_nest_event, %{name: :tool_initialized}}

    exit_attempt(view, attempt_id)
    assert_receive {:live_nest_event, %{name: :tool_completed}}
    exit_attempt(view, attempt_id)
    initialize_attempt(view, attempt_id)
    render_hook(view, "feldspar_unresponsive", %{attempt_id: attempt_id})
    refute_receive {:live_nest_event, %{name: :tool_completed}}
    refute_receive {:live_nest_event, %{name: :tool_initialized}}
    refute has_element?(view, "[data-testid='feldspar-recovery']")
  end

  test "events cannot start or finish an attempt before explicit start", %{view: view} do
    attempt_id = Ecto.UUID.generate()
    render_hook(view, "feldspar_recovery_checked", %{unfinished: false})
    render_hook(view, "feldspar_unresponsive", %{attempt_id: attempt_id})
    initialize_attempt(view, attempt_id)
    exit_attempt(view, attempt_id)

    refute has_element?(view, "iframe")
    refute has_element?(view, "[data-testid='feldspar-recovery']")
    assert has_element?(view, "[phx-click='prepare_start']")
    refute_receive {:live_nest_event, %{name: :tool_initialized}}
    refute_receive {:live_nest_event, %{name: :tool_completed}}
  end

  test "completion in another tab takes precedence over an unresponsive iframe", %{
    view: view,
    task: task
  } do
    attempt_id = start_attempt(view)
    task |> Ecto.Changeset.change(status: :completed) |> Repo.update!()
    render_hook(view, "feldspar_unresponsive", %{attempt_id: attempt_id})

    assert has_element?(view, "[data-completed='true']")
    refute has_element?(view, "[data-testid='feldspar-recovery']")
    refute has_element?(view, "[phx-click='prepare_start']")
    refute has_element?(view, "iframe")

    render_click(view, "prepare_start")
    render_hook(view, "start", %{attempt_id: Ecto.UUID.generate()})
    initialize_attempt(view, attempt_id)
    exit_attempt(view, attempt_id)
    render_hook(view, "feldspar_unresponsive", %{attempt_id: attempt_id})

    refute has_element?(view, "iframe")
    refute has_element?(view, "[data-testid='feldspar-recovery']")
    refute_receive {:live_nest_event, %{name: :tool_initialized}}
    refute_receive {:live_nest_event, %{name: :tool_completed}}
    assert Repo.get!(Crew.TaskModel, task.id).status == :completed
  end

  test "an iframe exit cannot complete an already completed task again", %{view: view, task: task} do
    attempt_id = start_attempt(view)
    task |> Ecto.Changeset.change(status: :completed) |> Repo.update!()
    exit_attempt(view, attempt_id)

    assert has_element?(view, "[data-completed='true']")
    refute has_element?(view, "iframe")
    refute has_element?(view, "[data-testid='feldspar-recovery']")
    refute_receive {:live_nest_event, %{name: :tool_completed}}
  end

  test "a nonzero exit is terminal without completing or recovering the task", %{
    view: view,
    task: task
  } do
    attempt_id = start_attempt(view)
    exit_attempt(view, attempt_id, 1)
    initialize_attempt(view, attempt_id)
    exit_attempt(view, attempt_id)
    render_hook(view, "feldspar_unresponsive", %{attempt_id: attempt_id})

    refute has_element?(view, "[data-testid='app-container'].block")
    refute has_element?(view, "[data-testid='feldspar-recovery']")
    refute_receive {:live_nest_event, %{name: :tool_initialized}}
    refute_receive {:live_nest_event, %{name: :tool_completed}}
    assert Repo.get!(Crew.TaskModel, task.id).status == :pending
  end

  defp start_attempt(view) do
    attempt_id = Ecto.UUID.generate()
    render_hook(view, "feldspar_recovery_checked", %{unfinished: false})
    render_click(view, "prepare_start")
    render_hook(view, "start", %{attempt_id: attempt_id})
    attempt_id
  end

  defp initialize_attempt(view, attempt_id) do
    render_hook(view, "feldspar_event", %{
      __type__: "CommandSystemEvent",
      name: "initialized",
      attempt_id: attempt_id
    })
  end

  defp exit_attempt(view, attempt_id, code \\ 0) do
    render_hook(view, "feldspar_event", %{
      __type__: "CommandSystemExit",
      code: code,
      info: "",
      attempt_id: attempt_id
    })
  end
end
