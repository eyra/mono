defmodule Systems.Feldspar.ToolViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Repo
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
        current_user: user,
        recovery: %{
          scope: "external-run/opaque-scope",
          on_entry: Map.get(test_context, :on_entry, :check)
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

  test "an unfinished attempt offers the support email without starting another attempt", %{
    view: view
  } do
    render_hook(view, "feldspar_recovery_checked", %{unfinished: true})

    assert has_element?(
             view,
             "[data-testid='feldspar-recovery'] a[href='mailto:support@eyra.co']"
           )

    refute has_element?(view, "[data-testid='feldspar-recovery-support']")
    assert has_element?(view, "[phx-click='prepare_start']")
    refute has_element?(view, "iframe")

    render_click(view, "prepare_start")
    render_hook(view, "start", %{attempt_id: Ecto.UUID.generate()})
    refute has_element?(view, "[data-testid='feldspar-recovery']")
    assert has_element?(view, "iframe")
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
end
