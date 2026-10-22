defmodule Systems.Probe.ToolViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Frameworks.Concept.LiveContext
  alias Systems.Assignment
  alias Systems.Workflow

  setup do
    isolate_signals()
    %{user: Factories.insert!(:member)}
  end

  test "a Probe task's start screen presents a test", %{conn: conn, user: user} do
    html = render_start_screen(conn, user, :probe)

    assert html =~ "You are about to start a test."
    refute html =~ "donate your data"
  end

  test "a Data donation task's start screen still presents a donation", %{conn: conn, user: user} do
    assert render_start_screen(conn, user, :donate) =~ "donate your data"
  end

  defp render_start_screen(conn, user, special) do
    tool = Factories.insert!(:feldspar_tool, %{archive_ref: "https://example.com/app"})

    tool_ref =
      Factories.insert!(:tool_ref, %{feldspar_tool: tool, special: special})
      |> Repo.preload(Workflow.ToolRefModel.preload_graph(:down))

    context =
      LiveContext.new(%{
        title: "Symbols",
        icon: nil,
        tool_ref: tool_ref,
        assignment_id: 123,
        participant: "participant",
        workflow_item_id: 456,
        current_user: user,
        recovery: %{scope: "scope", on_entry: :check, support_url: "mailto:support@example.org"}
      })

    %{element: %{options: options}} =
      Assignment.ToolViewFactory.prepare_modal(tool_ref, context, "tool_modal")

    {:ok, _view, html} =
      live_isolated(
        Map.put(conn, :request_path, "/feldspar/tool"),
        Systems.Feldspar.ToolView,
        session: %{"live_context" => Keyword.fetch!(options, :live_context)}
      )

    html
  end
end
