defmodule MicaSaas.Systems.Feldspar.ToolViewTest do
  use MicaSaasWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Mica.Repo
  alias Frameworks.Concept.LiveContext
  alias Systems.{Feldspar, Workflow}

  setup %{conn: conn} = test_context do
    isolate_signals()
    tool = Factories.insert!(:feldspar_tool, %{archive_ref: "https://example.com/app"})
    tool_ref = Factories.insert!(:tool_ref, %{feldspar_tool: tool})
    tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))
    user = Factories.insert!(:member)

    context =
      %{
        title: "Test Feldspar App",
        icon: "TikTok",
        tool_ref: tool_ref,
        assignment_id: 123,
        participant: "test_participant",
        workflow_item_id: 456,
        description: Map.get(test_context, :description),
        autostart: Map.get(test_context, :autostart, false),
        current_user: user,
        recovery: %{
          scope: "external-run/opaque-scope",
          on_entry: Map.get(test_context, :on_entry, :check),
          support_url: "mailto:support@eyra.co?subject=Help"
        }
      }
      |> Map.merge(Map.take(test_context, [:participant_task]))
      |> LiveContext.new()

    %{view: mount_tool_view(conn, context), conn: conn, context: context}
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

  test "an unfinished attempt adds a recovery block to the start screen while a new attempt loads",
       %{view: view} do
    render_hook(view, "feldspar_recovery_checked", %{unfinished: true})

    assert has_element?(
             view,
             "[data-testid='feldspar-recovery'] a[data-testid='feldspar-recovery-support'][href='mailto:support@eyra.co?subject=Help']"
           )

    assert has_element?(view, "[data-testid='start-container']", "Test Feldspar App")
    assert has_element?(view, "[phx-click='prepare_start']")
    refute has_element?(view, "iframe")

    render_click(view, "prepare_start")
    render_hook(view, "start", %{attempt_id: Ecto.UUID.generate()})
    assert has_element?(view, "iframe")
    assert has_element?(view, "[data-testid='feldspar-recovery']")
    assert has_element?(view, "[data-testid='feldspar-start'] .prism-button--loading")

    render_hook(view, "feldspar_event", %{__type__: "CommandSystemEvent", name: "initialized"})
    assert has_element?(view, "[data-testid='start-container'].hidden")
  end

  @tag on_entry: :clear_previous
  test "an entry that clears old recovery still allows a deliberate new attempt", %{view: view} do
    render_hook(view, "feldspar_recovery_checked", %{unfinished: false})

    refute has_element?(view, "[data-testid='feldspar-recovery']")
    refute has_element?(view, "iframe")
    assert has_element?(view, "[data-testid='feldspar-start'][phx-click='prepare_start']")

    render_click(view, "prepare_start")
    render_hook(view, "start", %{attempt_id: Ecto.UUID.generate()})

    assert has_element?(view, "iframe")
  end

  test "the start screen shows the default description", %{view: view} do
    assert has_element?(view, "[data-testid='start-container']", "donate your data")
  end

  @tag description: "You are about to start a test."
  test "the start screen shows the description from the host", %{view: view} do
    assert has_element?(view, "[data-testid='start-container']", "You are about to start a test.")
    refute has_element?(view, "[data-testid='start-container']", "donate your data")
  end

  @tag autostart: true
  test "with autostart, the start screen is left out", %{view: view} do
    assert has_element?(view, "[data-testid='feldspar-autostart']")
    refute has_element?(view, "[data-testid='feldspar-start']")
  end

  @tag autostart: true
  test "with autostart, the app starts once recovery is checked", %{view: view} do
    render_hook(view, "feldspar_recovery_checked", %{unfinished: false})
    assert_push_event(view, "feldspar:prepare", %{id: _})

    render_hook(view, "start", %{attempt_id: Ecto.UUID.generate()})
    assert has_element?(view, "iframe")
  end

  # After a reload or a crash the modal reopens; the notice must be readable before a
  # new attempt, as on the vertical list's start screen
  @tag autostart: true
  test "with autostart, an unfinished attempt shows the start screen with its notice instead",
       %{view: view} do
    render_hook(view, "feldspar_recovery_checked", %{unfinished: true})

    refute_push_event(view, "feldspar:prepare", %{id: _})
    assert has_element?(view, "[data-testid='feldspar-recovery']")
    assert has_element?(view, "[data-testid='feldspar-start'][phx-click='prepare_start']")
    refute has_element?(view, "[data-testid='feldspar-autostart']")
  end

  @tag participant_task: "81234"
  test "the app gets a hash of the host's participant_task for live-init, not the id", %{
    view: view
  } do
    start(view)

    assert participant_task(view) =~ ~r/\A[A-Za-z0-9_-]{22}\z/
    refute participant_task(view) =~ "81234"
  end

  @tag participant_task: "81234"
  test "the app gets the same participant_task after a reload", %{
    view: view,
    conn: conn,
    context: context
  } do
    start(view)
    reloaded = mount_tool_view(conn, context)
    start(reloaded)

    assert participant_task(reloaded) == participant_task(view)
  end

  test "without a participant_task from the host, the app gets none", %{view: view} do
    start(view)

    assert has_element?(view, "[phx-hook='FeldsparApp']")
    refute has_element?(view, "[data-participant-task]")
  end

  test "without autostart, checking recovery doesn't start the app", %{view: view} do
    render_hook(view, "feldspar_recovery_checked", %{unfinished: false})
    render_hook(view, "start", %{attempt_id: Ecto.UUID.generate()})

    refute has_element?(view, "iframe")
  end

  defp mount_tool_view(conn, context) do
    {:ok, view, _html} =
      live_isolated(
        Map.put(conn, :request_path, "/feldspar/tool"),
        Feldspar.ToolView,
        session: %{"live_context" => context}
      )

    view
  end

  defp participant_task(view) do
    [_, participant_task] =
      Regex.run(~r/data-participant-task="([^"]+)"/, render(view))

    participant_task
  end

  defp start(view) do
    render_hook(view, "feldspar_recovery_checked", %{unfinished: false})
    render_click(view, "prepare_start")
    render_hook(view, "start", %{attempt_id: Ecto.UUID.generate()})
  end
end
