defmodule Systems.Feldspar.ToolViewTest do
  use MicaWeb.ConnCase, async: false
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
      LiveContext.new(%{
        title: "Test Feldspar App",
        icon: "TikTok",
        tool_ref: tool_ref,
        assignment_id: 123,
        participant: "test_participant",
        workflow_item_id: 456,
        description: Map.get(test_context, :description),
        presentation: Map.get(test_context, :presentation, :embedded),
        current_user: user,
        recovery: %{
          scope: "external-run/opaque-scope",
          on_entry: Map.get(test_context, :on_entry, :check),
          support_url: "mailto:support@eyra.co?subject=Help"
        }
      })

    {:ok, view, _html} =
      live_isolated(
        Map.put(conn, :request_path, "/feldspar/tool"),
        Feldspar.ToolView,
        session: %{"live_context" => context}
      )

    %{view: view}
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

  test "the app takes the start screen's place", %{view: view} do
    start_app(view)

    refute has_element?(view, "[data-testid='app-modal']")
    assert has_element?(view, "[data-testid='start-container'].hidden")
  end

  @tag presentation: :start_on_page
  test "with the start screen on the page, the app opens in a modal over it", %{view: view} do
    render_hook(view, "feldspar_recovery_checked", %{unfinished: false})
    render_click(view, "prepare_start")
    render_hook(view, "start", %{attempt_id: Ecto.UUID.generate()})

    assert has_element?(view, "[data-testid='app-modal'].opacity-0 iframe")

    render_hook(view, "feldspar_event", %{__type__: "CommandSystemEvent", name: "initialized"})

    assert has_element?(
             view,
             "[data-testid='app-modal'].fixed [data-testid='app-container'].block"
           )

    refute has_element?(view, "[data-testid='app-modal'].opacity-0")
    assert has_element?(view, "[data-testid='start-container'].flex")
  end

  # A Feldspar app sizes its iframe to its content, so a tall app must scroll in the modal
  @tag presentation: :start_on_page
  test "the app modal scrolls an app taller than the modal", %{view: view} do
    start_app(view)

    assert has_element?(
             view,
             "[data-testid='app-modal'] [data-testid='app-modal-body'].overflow-y-scroll [data-testid='app-container']"
           )
  end

  defp start_app(view) do
    render_hook(view, "feldspar_recovery_checked", %{unfinished: false})
    render_click(view, "prepare_start")
    render_hook(view, "start", %{attempt_id: Ecto.UUID.generate()})
    render_hook(view, "feldspar_event", %{__type__: "CommandSystemEvent", name: "initialized"})
  end
end
