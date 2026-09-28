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

    {:ok, view, _html} =
      live_isolated(
        Map.put(conn, :request_path, "/feldspar/tool"),
        Feldspar.ToolView,
        session: %{"live_context" => context}
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
    render_hook(view, "start", %{attempt_id: Ecto.UUID.generate()})
    assert has_element?(view, "iframe")

    render_hook(view, "feldspar_event", %{
      __type__: "CommandSystemEvent",
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

    support_uri =
      view
      |> element("a[data-testid='feldspar-recovery-support']")
      |> render()
      |> Floki.parse_fragment!()
      |> Floki.attribute("href")
      |> List.first()
      |> URI.parse()

    assert support_uri.path == "/support/helpdesk"

    assert URI.decode_query(support_uri.query) == %{
             "assignment_id" => "123",
             "context" => "feldspar_recovery",
             "task_id" => to_string(task.id),
             "task_name" => "Test Feldspar App"
           }

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
end
