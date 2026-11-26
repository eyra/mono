defmodule Next.Systems.Zircon.Screening.ContentPageSessionTest do
  @moduledoc """
  The import and criteria tabs of a paper screening hand their LiveViews a
  session inside the page's HTML; it carries no user.
  """
  use NextWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Mica.Test.EmbeddedSessions
  alias Systems.Account
  alias Systems.Assignment
  alias Systems.Project

  setup :login_as_creator

  setup %{user: user} do
    tool = Factories.insert!(:zircon_screening_tool, %{})

    tool_ref =
      Factories.insert!(:tool_ref, %{zircon_screening_tool: tool, special: :paper_screening})

    workflow = Assignment.Factories.create_workflow()
    _item = Assignment.Factories.create_workflow_item(workflow, tool_ref)
    auth_node = Factories.insert!(:auth_node)

    assignment =
      Factories.insert!(:assignment, %{
        info: Assignment.Factories.create_info("10", 100),
        workflow: workflow,
        crew: Factories.insert!(:crew),
        auth_node: auth_node,
        special: :paper_screening,
        status: :concept
      })

    assignment
    |> Project.Factories.build_item()
    |> Project.Factories.build_node()
    |> Project.Factories.build_project()
    |> Mica.Repo.insert!()

    Factories.insert!(:role_assignment, %{node: auth_node, role: :owner, principal_id: user.id})

    {:ok, assignment: assignment}
  end

  test "the import and criteria tabs carry no user", %{conn: conn, assignment: assignment} do
    {:ok, view, _html} =
      conn
      |> put_connect_params(%{"viewport" => %{"width" => 1280, "height" => 800}})
      |> live(~m"/assignment/#{assignment.id}/content")

    assert find_live_child(view, "import")
    assert find_live_child(view, "criteria")
    refute Account.User in EmbeddedSessions.structs(render(view), @endpoint)
  end
end
