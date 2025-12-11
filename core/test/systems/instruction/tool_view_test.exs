defmodule Systems.Instruction.ToolViewTest do
  use CoreWeb.ConnCase, async: false
  use Gettext, backend: CoreWeb.Gettext
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Systems.Instruction
  alias Systems.Workflow

  setup do
    isolate_signals()

    %{}
  end

  describe "basic rendering" do
    test "renders tool view with done button", %{conn: conn} do
      auth_node = Factories.insert!(:auth_node)
      tool = Repo.insert!(%Instruction.ToolModel{auth_node_id: auth_node.id})
      tool = Repo.preload(tool, [:pages])

      tool_ref = Factories.insert!(:tool_ref, %{instruction_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      conn = conn |> Map.put(:request_path, "/instruction/tool")

      live_context = Frameworks.Concept.LiveContext.new(%{tool_ref: tool_ref})

      session = %{"live_context" => live_context}

      {:ok, _view, html} = live_isolated(conn, Instruction.ToolView, session: session)

      # Should render done button
      assert html =~ dgettext("eyra-ui", "done.button")
    end

    test "renders page view when tool has pages", %{conn: conn} do
      auth_node = Factories.insert!(:auth_node)
      tool = Repo.insert!(%Instruction.ToolModel{auth_node_id: auth_node.id})
      page = Factories.insert!(:content_page)

      # Create instruction page reference
      Repo.insert!(%Instruction.PageModel{
        tool_id: tool.id,
        page_id: page.id
      })

      tool = Repo.preload(tool, [pages: :page], force: true)

      tool_ref = Factories.insert!(:tool_ref, %{instruction_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      conn = conn |> Map.put(:request_path, "/instruction/tool")

      live_context = Frameworks.Concept.LiveContext.new(%{tool_ref: tool_ref})

      session = %{"live_context" => live_context}

      {:ok, _view, html} = live_isolated(conn, Instruction.ToolView, session: session)

      # Should render page view title
      assert html =~ dgettext("eyra-instruction", "page.title")
    end
  end

  describe "event handlers" do
    setup do
      auth_node = Factories.insert!(:auth_node)
      tool = Repo.insert!(%Instruction.ToolModel{auth_node_id: auth_node.id})
      tool = Repo.preload(tool, [:pages])

      tool_ref = Factories.insert!(:tool_ref, %{instruction_tool: tool})
      tool_ref = Repo.preload(tool_ref, Workflow.ToolRefModel.preload_graph(:down))

      %{tool: tool, tool_ref: tool_ref}
    end

    test "handles done event", %{conn: conn, tool_ref: tool_ref} do
      conn = conn |> Map.put(:request_path, "/instruction/tool")

      live_context = Frameworks.Concept.LiveContext.new(%{tool_ref: tool_ref})

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Instruction.ToolView, session: session)

      # Send done event
      html = view |> render_click("done")

      # Verify view still renders (event was handled)
      assert html =~ dgettext("eyra-ui", "done.button")
    end
  end
end
