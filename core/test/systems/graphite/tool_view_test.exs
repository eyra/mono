defmodule Systems.Graphite.ToolViewTest do
  use CoreWeb.ConnCase, async: false
  use Gettext, backend: CoreWeb.Gettext
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Systems.Graphite
  alias Systems.Workflow

  setup do
    isolate_signals()

    user = Factories.insert!(:member)

    %{user: user}
  end

  describe "basic rendering" do
    test "renders tool view with submission form", %{conn: conn, user: user} do
      tool = Graphite.Factories.create_tool()
      tool_ref = Factories.insert!(:tool_ref, %{graphite_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      conn = conn |> Map.put(:request_path, "/graphite/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          current_user: user,
          timezone: "UTC",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, _view, html} = live_isolated(conn, Graphite.ToolView, session: session)

      # Should render submission title
      assert html =~ dgettext("eyra-graphite", "submission.title")

      # Should render leaderboard title
      assert html =~ dgettext("eyra-graphite", "leaderboard.title")
    end

    test "renders leaderboard description when no leaderboard button", %{conn: conn, user: user} do
      tool = Graphite.Factories.create_tool()
      tool_ref = Factories.insert!(:tool_ref, %{graphite_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      conn = conn |> Map.put(:request_path, "/graphite/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          current_user: user,
          timezone: "UTC",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, _view, html} = live_isolated(conn, Graphite.ToolView, session: session)

      # Should render leaderboard description
      assert html =~ dgettext("eyra-graphite", "leaderboard.description")
    end
  end

  describe "event handlers" do
    setup do
      tool = Graphite.Factories.create_tool()
      tool_ref = Factories.insert!(:tool_ref, %{graphite_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      %{tool: tool, tool_ref: tool_ref}
    end

    test "handles done event", %{conn: conn, user: user, tool_ref: tool_ref} do
      conn = conn |> Map.put(:request_path, "/graphite/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          current_user: user,
          timezone: "UTC",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Graphite.ToolView, session: session)

      # Send done event
      html = view |> render_click("done")

      # Verify view still renders (event was handled without error)
      assert html =~ dgettext("eyra-graphite", "submission.title")
    end

    test "handles go_to_leaderboard event", %{conn: conn, user: user, tool_ref: tool_ref} do
      conn = conn |> Map.put(:request_path, "/graphite/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          current_user: user,
          timezone: "UTC",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Graphite.ToolView, session: session)

      # Send go_to_leaderboard event
      html = view |> render_click("go_to_leaderboard")

      # Verify view still renders (event was handled without error)
      assert html =~ dgettext("eyra-graphite", "submission.title")
    end
  end

  describe "timezone handling" do
    test "uses timezone from context", %{conn: conn, user: user} do
      tool = Graphite.Factories.create_tool()
      tool_ref = Factories.insert!(:tool_ref, %{graphite_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      conn = conn |> Map.put(:request_path, "/graphite/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          current_user: user,
          timezone: "Europe/Amsterdam",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, _view, html} = live_isolated(conn, Graphite.ToolView, session: session)

      # Verify view renders correctly with Amsterdam timezone
      assert html =~ dgettext("eyra-graphite", "submission.title")
    end
  end
end
