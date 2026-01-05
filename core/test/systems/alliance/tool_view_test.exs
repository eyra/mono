defmodule Systems.Alliance.ToolViewTest do
  use CoreWeb.ConnCase, async: false
  use Gettext, backend: CoreWeb.Gettext
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Systems.Alliance
  alias Systems.Workflow

  setup do
    isolate_signals()

    %{}
  end

  describe "basic rendering" do
    test "renders tool view with title and description", %{conn: conn} do
      tool = Factories.insert!(:alliance_tool, %{url: "https://external-survey.example.com"})
      tool_ref = Factories.insert!(:tool_ref, %{alliance_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      conn = conn |> Map.put(:request_path, "/alliance/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          title: "Test Alliance Survey",
          description: "Test description",
          url: "https://external-survey.example.com?participant=123",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, _view, html} = live_isolated(conn, Alliance.ToolView, session: session)

      # Should render title
      assert html =~ "Test Alliance Survey"

      # Should render description
      assert html =~ "Test description"
    end

    test "renders button with correct label", %{conn: conn} do
      tool = Factories.insert!(:alliance_tool, %{url: "https://external-survey.example.com"})
      tool_ref = Factories.insert!(:tool_ref, %{alliance_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      conn = conn |> Map.put(:request_path, "/alliance/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          title: "Test Survey",
          description: "Test description",
          url: "https://external-survey.example.com",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, _view, html} = live_isolated(conn, Alliance.ToolView, session: session)

      # Should render button label
      assert html =~ dgettext("eyra-alliance", "tool.button")
    end
  end

  describe "event handlers" do
    setup do
      tool = Factories.insert!(:alliance_tool, %{url: "https://external-survey.example.com"})
      tool_ref = Factories.insert!(:tool_ref, %{alliance_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      %{tool: tool, tool_ref: tool_ref}
    end

    test "handles tool_started event", %{conn: conn, tool_ref: tool_ref} do
      conn = conn |> Map.put(:request_path, "/alliance/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          title: "Test Survey",
          description: "Test description",
          url: "https://external-survey.example.com",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Alliance.ToolView, session: session)

      # Send start_tool event
      html = view |> render_click("start_tool")

      # Verify view handled the event (view still renders)
      assert html =~ "Test Survey"
    end
  end

  describe "url handling" do
    test "renders with url containing participant", %{conn: conn} do
      tool = Factories.insert!(:alliance_tool, %{url: "https://external-survey.example.com"})
      tool_ref = Factories.insert!(:tool_ref, %{alliance_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      conn = conn |> Map.put(:request_path, "/alliance/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          title: "Test Survey",
          description: "Survey for participant-123",
          url: "https://external-survey.example.com?participant=participant-123",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, _view, html} = live_isolated(conn, Alliance.ToolView, session: session)

      # Should render correctly
      assert html =~ "Test Survey"
      assert html =~ "Survey for participant-123"
    end

    test "renders with url without participant", %{conn: conn} do
      tool = Factories.insert!(:alliance_tool, %{url: "https://external-survey.example.com"})
      tool_ref = Factories.insert!(:tool_ref, %{alliance_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      conn = conn |> Map.put(:request_path, "/alliance/tool")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          title: "Test Survey",
          description: "Generic survey description",
          url: "https://external-survey.example.com",
          tool_ref: tool_ref
        })

      session = %{"live_context" => live_context}

      {:ok, _view, html} = live_isolated(conn, Alliance.ToolView, session: session)

      # Should render correctly
      assert html =~ "Test Survey"
      assert html =~ "Generic survey description"
    end
  end
end
