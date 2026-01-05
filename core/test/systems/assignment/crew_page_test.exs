defmodule Systems.Assignment.CrewPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Systems.Assignment
  alias Systems.Manual

  setup :login_as_member

  setup do
    advert_auth_node = Factories.insert!(:auth_node)
    assignment_auth_node = Factories.insert!(:auth_node, %{parent: advert_auth_node})
    tool_auth_node = Factories.insert!(:auth_node, %{parent: assignment_auth_node})

    tool = Assignment.Factories.create_tool(tool_auth_node)
    tool_ref = Assignment.Factories.create_tool_ref(tool)
    workflow = Assignment.Factories.create_workflow()
    _workflow_item = Assignment.Factories.create_workflow_item(workflow, tool_ref)
    info = Assignment.Factories.create_info("10", 100)

    assignment =
      Assignment.Factories.create_assignment(
        info,
        # consent_agreement
        nil,
        workflow,
        assignment_auth_node,
        :online
      )

    {:ok, assignment: assignment, tool: tool}
  end

  describe "render an assignment crew page" do
    test "renders page", %{conn: conn, assignment: assignment, user: user} do
      conn = put_session(conn, :panel_info, %{redirect?: false, participant: "test"})
      Assignment.Public.add_participant!(assignment, user)

      {:ok, _view, html} = live(conn, ~p"/assignment/#{assignment.id}")
      assert html =~ "<div id=\"crew_page\""
    end
  end

  describe "render crew page with manual tool" do
    setup do
      advert_auth_node = Factories.insert!(:auth_node)
      assignment_auth_node = Factories.insert!(:auth_node, %{parent: advert_auth_node})
      tool_auth_node = Factories.insert!(:auth_node, %{parent: assignment_auth_node})

      # Create manual tool with chapters and pages
      manual_tool = Manual.Factories.create_manual_tool(2, 3, tool_auth_node)
      manual_tool = Core.Repo.preload(manual_tool, manual: [chapters: [:pages]])
      manual = manual_tool.manual
      [chapter1, _chapter2] = manual.chapters

      # Create tool_ref for manual
      tool_ref =
        Factories.insert!(:tool_ref, %{
          manual_tool: manual_tool,
          special: :manual
        })

      workflow = Assignment.Factories.create_workflow()
      _workflow_item = Assignment.Factories.create_workflow_item(workflow, tool_ref)
      info = Assignment.Factories.create_info("10", 100)

      assignment =
        Assignment.Factories.create_assignment(
          info,
          nil,
          workflow,
          assignment_auth_node,
          :online
        )

      {:ok, assignment: assignment, manual: manual, chapter1: chapter1}
    end

    test "renders manual with local toolbar - debug HTML structure", %{
      conn: conn,
      assignment: assignment,
      user: user,
      manual: manual,
      chapter1: chapter1
    } do
      conn = put_session(conn, :panel_info, %{redirect?: false, participant: "test"})

      Assignment.Public.add_participant!(assignment, user)

      # Set user state via connect params with proper key format
      user_state_key = "next://user-#{user.id}@localhost/manual/#{manual.id}/chapter"
      user_state = %{user_state_key => to_string(chapter1.id)}

      {:ok, _view, html} =
        conn
        |> put_connect_params(%{"user_state" => user_state})
        |> live(~p"/assignment/#{assignment.id}")

      # Save HTML to file for analysis
      File.write!("/tmp/crew_page_test.html", html)
      IO.puts("\n\n=== HTML saved to /tmp/crew_page_test.html ===\n\n")

      assert html =~ "crew_page"
    end
  end
end
