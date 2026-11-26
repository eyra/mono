defmodule MicaSaasWeb.Live.EmbeddedSessionTest do
  @moduledoc """
  A page hands each embedded LiveView its session inside the HTML. Those
  sessions carry ids, never records: no user and no tool reference.
  """
  use MicaSaasWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Mica.Test.EmbeddedSessions
  alias Systems.Account
  alias Systems.Assignment
  alias Systems.Manual
  alias Systems.Org
  alias Systems.Workflow

  @records [Account.User, Workflow.ToolRefModel]

  describe "crew page" do
    setup :login_as_member

    setup %{user: user} do
      tool_auth_node = Factories.insert!(:auth_node)
      manual_tool = Manual.Factories.create_manual_tool(1, 1, tool_auth_node)
      tool_ref = Factories.insert!(:tool_ref, %{manual_tool: manual_tool, special: :manual})
      workflow = Assignment.Factories.create_workflow()
      _item = Assignment.Factories.create_workflow_item(workflow, tool_ref)
      info = Assignment.Factories.create_info("10", 100)
      auth_node = Factories.insert!(:auth_node)

      assignment =
        Assignment.Factories.create_assignment(info, nil, workflow, auth_node, :online)

      Assignment.Public.add_participant!(assignment, user)
      {:ok, assignment: assignment}
    end

    test "carries no records", %{conn: conn, assignment: assignment} do
      conn = put_session(conn, :panel_info, %{redirect?: false, participant: "test"})

      {:ok, view, _html} =
        conn
        |> put_connect_params(%{"user_state" => %{}})
        |> live(~m"/assignment/#{assignment.id}")

      views = with_children(view)

      assert Manual.ToolView in Enum.map(views, & &1.module)
      assert_no_records(Enum.map_join(views, &render/1))
    end
  end

  describe "admin config page" do
    setup :login_as_admin

    test "carries no records", %{conn: conn} do
      Factories.insert!(:creator)

      {:ok, _view, html} = live(conn, ~m"/admin/config")

      assert_no_records(html)
    end
  end

  describe "admin config page for an org owner" do
    setup :login_as_creator

    test "carries no records", %{conn: conn, user: user} do
      for name <- ["embedded_session_org_a", "embedded_session_org_b"] do
        org = Factories.insert!(:org_node, %{identifier: [name]})
        :ok = Org.Public.assign_owner(org, user)
        Org.Public.add_user(org, Factories.insert!(:member))
      end

      {:ok, view, html} = live(conn, ~m"/admin/config")

      assert find_live_child(view, "admin_org_view")
      assert_no_records(html)
    end
  end

  describe "org page" do
    setup :login_as_creator

    test "carries no records", %{conn: conn, user: user} do
      org = Factories.insert!(:org_node, %{identifier: ["embedded_session_org"]})
      :ok = Org.Public.assign_owner(org, user)

      {:ok, _view, html} = live(conn, ~m"/org/node/#{org.id}")

      assert_no_records(html)
    end
  end

  describe "pool page" do
    setup :login_as_admin

    test "carries no records", %{conn: conn} do
      pool = Factories.insert!(:pool, %{name: "embedded_session_pool", director: :citizen})

      {:ok, _view, html} = live(conn, ~m"/pool/#{pool.id}/content")

      assert_no_records(html)
    end
  end

  defp with_children(view), do: [view | Enum.flat_map(live_children(view), &with_children/1)]

  defp assert_no_records(html) do
    assert [_ | _] = EmbeddedSessions.sessions(html, @endpoint)
    assert [] = EmbeddedSessions.structs(html, @endpoint) |> Enum.filter(&(&1 in @records))
  end
end
