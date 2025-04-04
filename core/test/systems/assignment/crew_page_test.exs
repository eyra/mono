defmodule Systems.Assignment.CrewPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Systems.Assignment

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
        workflow,
        assignment_auth_node,
        :online
      )

    {:ok, assignment: assignment, tool: tool}
  end

  describe "render an assignment crew page" do
    test "renders page", %{conn: conn, assignment: assignment, user: user, tool: tool} do
      conn = put_session(conn, :panel_info, %{embedded?: false, participant: "test"})
      Assignment.Public.add_participant!(assignment, user)

      {:ok, _view, html} = live(conn, ~p"/assignment/#{assignment.id}")
      assert html =~ "<a href=\"#{tool.url}?participant=test\" target=\"_blank\">"
    end
  end
end
