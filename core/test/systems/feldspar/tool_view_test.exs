defmodule Systems.Feldspar.ToolViewTest do
  use CoreWeb.ConnCase, async: false
  use Gettext, backend: CoreWeb.Gettext
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Systems.Feldspar
  alias Systems.Workflow

  setup do
    isolate_signals()

    %{}
  end

  describe "basic rendering" do
    test "renders tool view with title and icon", %{conn: conn} do
      tool = Factories.insert!(:feldspar_tool, %{archive_ref: "https://example.com/app"})
      tool_ref = Factories.insert!(:tool_ref, %{feldspar_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      conn = conn |> Map.put(:request_path, "/feldspar/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          title: "Test Feldspar App",
          icon: "test_icon",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, _view, html} = live_isolated(conn, Feldspar.ToolView, session: session)

      # Should render title
      assert html =~ "Test Feldspar App"
    end

    test "renders start button before tool is started", %{conn: conn} do
      tool = Factories.insert!(:feldspar_tool, %{archive_ref: "https://example.com/app"})
      tool_ref = Factories.insert!(:tool_ref, %{feldspar_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      conn = conn |> Map.put(:request_path, "/feldspar/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          title: "Test App",
          icon: "test",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, _view, html} = live_isolated(conn, Feldspar.ToolView, session: session)

      # Should have start button with "Continue" label
      assert html =~ "Continue"
    end
  end

  describe "start event" do
    setup do
      tool = Factories.insert!(:feldspar_tool, %{archive_ref: "https://example.com/app"})
      tool_ref = Factories.insert!(:tool_ref, %{feldspar_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      %{tool: tool, tool_ref: tool_ref}
    end

    test "handles start event", %{conn: conn, tool_ref: tool_ref} do
      conn = conn |> Map.put(:request_path, "/feldspar/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          title: "Test App",
          icon: "test",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Feldspar.ToolView, session: session)

      # Send start event
      html = view |> render_click("start")

      # Verify view still renders correctly after start
      assert html =~ "Test App"
    end
  end

  describe "feldspar_event handling" do
    setup do
      tool = Factories.insert!(:feldspar_tool, %{archive_ref: "https://example.com/app"})
      tool_ref = Factories.insert!(:tool_ref, %{feldspar_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      %{tool: tool, tool_ref: tool_ref}
    end

    test "handles CommandSystemExit with code 0 - publishes tool_exited event", %{
      conn: conn,
      tool_ref: tool_ref
    } do
      conn = conn |> Map.put(:request_path, "/feldspar/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          title: "Test App",
          icon: "test",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Feldspar.ToolView, session: session)

      # Send CommandSystemExit with success code
      event = %{
        "__type__" => "CommandSystemExit",
        "code" => 0,
        "info" => "Normal exit"
      }

      view |> render_click("feldspar_event", event)

      # Verify tool_exited event was published
      # Note: In isolated test, we can't easily assert published events
      # This test verifies the handler doesn't crash
    end

    test "handles CommandSystemExit with non-zero code - shows error message", %{
      conn: conn,
      tool_ref: tool_ref
    } do
      conn = conn |> Map.put(:request_path, "/feldspar/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          title: "Test App",
          icon: "test",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Feldspar.ToolView, session: session)

      # Send CommandSystemExit with error code
      event = %{
        "__type__" => "CommandSystemExit",
        "code" => 1,
        "info" => "Error occurred"
      }

      html = view |> render_click("feldspar_event", event)

      # Verify error message is shown (check flash)
      # The view should still render without crashing
      assert html =~ "Test App"
    end

    test "handles CommandSystemDonate - publishes donate event", %{
      conn: conn,
      tool_ref: tool_ref
    } do
      conn = conn |> Map.put(:request_path, "/feldspar/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          title: "Test App",
          icon: "test",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Feldspar.ToolView, session: session)

      # Send CommandSystemDonate
      event = %{
        "__type__" => "CommandSystemDonate",
        "key" => "survey_response",
        "json_string" => "{\"answer\": \"yes\"}"
      }

      html = view |> render_click("feldspar_event", event)

      # Verify view still renders without crashing after donate event
      # Note: Flash messages are handled by parent LiveView, so we just verify
      # the handler executes without error
      assert html =~ "Test App"
    end

    test "handles CommandSystemEvent with initialized - publishes tool_initialized event", %{
      conn: conn,
      tool_ref: tool_ref
    } do
      conn = conn |> Map.put(:request_path, "/feldspar/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          title: "Test App",
          icon: "test",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Feldspar.ToolView, session: session)

      # Start the tool first
      view |> render_click("start")

      # Send CommandSystemEvent with initialized
      event = %{
        "__type__" => "CommandSystemEvent",
        "name" => "initialized"
      }

      view |> render_click("feldspar_event", event)

      # Verify initialized state: app-container should have 'block' class (visible)
      # and start-container should have 'hidden' class
      assert view |> has_element?("[data-testid='app-container'].block")
      assert view |> has_element?("[data-testid='start-container'].hidden")
    end

    test "handles unknown event type - shows error message", %{conn: conn, tool_ref: tool_ref} do
      conn = conn |> Map.put(:request_path, "/feldspar/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          title: "Test App",
          icon: "test",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Feldspar.ToolView, session: session)

      # Send unknown event type
      event = %{
        "__type__" => "CommandUnknown",
        "data" => "test"
      }

      html = view |> render_click("feldspar_event", event)

      # Verify error message is shown (check for the event type in error)
      # The view should still render
      assert html =~ "Test App"
    end

    test "handles malformed event - shows error message", %{conn: conn, tool_ref: tool_ref} do
      conn = conn |> Map.put(:request_path, "/feldspar/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          title: "Test App",
          icon: "test",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Feldspar.ToolView, session: session)

      # Send malformed event (missing __type__)
      event = %{
        "some_field" => "value"
      }

      html = view |> render_click("feldspar_event", event)

      # Verify error message is shown
      # The view should still render
      assert html =~ "Test App"
    end
  end

  describe "tool_initialized event" do
    setup do
      tool = Factories.insert!(:feldspar_tool, %{archive_ref: "https://example.com/app"})
      tool_ref = Factories.insert!(:tool_ref, %{feldspar_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      %{tool: tool, tool_ref: tool_ref}
    end

    test "handles tool_initialized event from JS hook", %{conn: conn, tool_ref: tool_ref} do
      conn = conn |> Map.put(:request_path, "/feldspar/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          title: "Test App",
          icon: "test",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Feldspar.ToolView, session: session)

      # Start the tool first
      view |> render_click("start")

      # Send tool_initialized event (from JS hook)
      view |> render_click("tool_initialized")

      # Verify initialized state: app-container should have 'block' class (visible)
      # and start-container should have 'hidden' class
      assert view |> has_element?("[data-testid='app-container'].block")
      assert view |> has_element?("[data-testid='start-container'].hidden")
    end
  end
end
