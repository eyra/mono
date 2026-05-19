defmodule Systems.Org.UserViewTest do
  @moduledoc """
  Regression coverage for FX#9905890143 — a stale LiveView session
  belonging to a user whose :owner role was revoked must not be able to
  mutate the org's membership.
  """
  use CoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Frameworks.Concept.LiveContext
  alias Systems.Org

  describe "UserView authorization" do
    setup ctx do
      owner = Factories.insert!(:creator)
      {:ok, ctx} = login(owner, ctx)
      conn = ctx[:conn] |> Map.put(:request_path, "/org/node")

      org =
        Factories.insert!(:org_node, %{
          identifier: ["user_view_auth_org"],
          domains: ["user-view-auth.test"]
        })

      :ok = Org.Public.assign_owner(org, owner)

      context =
        LiveContext.new(%{
          node_id: org.id,
          current_user: owner,
          locale: :en
        })

      {:ok, conn: conn, owner: owner, org: org, context: context}
    end

    test "handle_info {:add_user, ...} no-ops after owner role is revoked",
         %{conn: conn, owner: owner, org: org, context: context} do
      candidate = Factories.insert!(:creator)

      {:ok, view, _html} =
        live_isolated(conn, Org.UserView, session: %{"live_context" => context})

      :ok = Org.Public.revoke_owner(org, owner)

      send(view.pid, {:add_user, %{user: candidate}})
      _ = render(view)

      member_ids = Enum.map(Org.Public.list_members(org), & &1.id)
      refute candidate.id in member_ids
    end

    test "handle_info {:remove_user, ...} no-ops after owner role is revoked",
         %{conn: conn, owner: owner, org: org, context: context} do
      member = Factories.insert!(:creator)
      Org.Public.add_member(org, member)

      {:ok, view, _html} =
        live_isolated(conn, Org.UserView, session: %{"live_context" => context})

      :ok = Org.Public.revoke_owner(org, owner)

      send(view.pid, {:remove_user, %{user: member}})
      _ = render(view)

      member_ids = Enum.map(Org.Public.list_members(org), & &1.id)
      assert member.id in member_ids
    end

    test "handle_event add_all_domain_matched no-ops after owner role is revoked",
         %{conn: conn, owner: owner, org: org, context: context} do
      candidate = Factories.insert!(:creator, %{email: "candidate@user-view-auth.test"})

      {:ok, view, _html} =
        live_isolated(conn, Org.UserView, session: %{"live_context" => context})

      :ok = Org.Public.revoke_owner(org, owner)

      render_click(view, "add_all_domain_matched", %{})

      member_ids = Enum.map(Org.Public.list_members(org), & &1.id)
      refute candidate.id in member_ids
    end
  end
end
