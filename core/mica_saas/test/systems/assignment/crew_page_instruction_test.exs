defmodule MicaSaas.Systems.Assignment.CrewPageInstructionTest do
  use MicaSaasWeb.ConnCase, async: false
  use Gettext, backend: MicaWeb.Gettext
  import Phoenix.LiveViewTest

  alias Mica.Repo
  alias Systems.Assignment
  alias Systems.Instruction

  setup :login_as_member

  setup %{user: user} do
    tool_auth_node = Factories.insert!(:auth_node)
    tool = Repo.insert!(%Instruction.ToolModel{auth_node_id: tool_auth_node.id})
    page = Factories.insert!(:content_page)
    Repo.insert!(%Instruction.PageModel{tool_id: tool.id, page_id: page.id})

    tool_ref = Factories.insert!(:tool_ref, %{instruction_tool: tool, special: :instruction})
    workflow = Assignment.Factories.create_workflow()
    _item = Assignment.Factories.create_workflow_item(workflow, tool_ref)
    info = Assignment.Factories.create_info("10", 100)
    auth_node = Factories.insert!(:auth_node)

    assignment =
      Assignment.Factories.create_assignment(info, nil, workflow, auth_node, :online)

    Assignment.Public.add_participant!(assignment, user)
    {:ok, assignment: assignment}
  end

  test "an instruction task shows its page", %{conn: conn, assignment: assignment} do
    conn = put_session(conn, :panel_info, %{redirect?: false, participant: "test"})

    {:ok, view, _html} =
      conn
      |> put_connect_params(%{"user_state" => %{}})
      |> live(~m"/assignment/#{assignment.id}")

    [tool_view] = view |> with_children() |> Enum.filter(&(&1.module == Instruction.ToolView))

    assert render(tool_view) =~ dgettext("eyra-instruction", "page.title")
  end

  defp with_children(view), do: [view | Enum.flat_map(live_children(view), &with_children/1)]
end
