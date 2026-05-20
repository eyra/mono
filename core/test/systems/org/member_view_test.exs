defmodule Systems.Org.MemberViewTest do
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

  describe "MemberView authorization" do
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
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

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
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

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
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

      :ok = Org.Public.revoke_owner(org, owner)

      render_click(view, "add_all_domain_matched", %{})

      member_ids = Enum.map(Org.Public.list_members(org), & &1.id)
      refute candidate.id in member_ids
    end
  end

  # Coverage for FX#9905891585 — the Members tab now has a search bar and
  # filter chips driven by Pixel.SearchBar + Pixel.Selector, which talk
  # to the LiveView via consume_event(:search_query) and
  # handle_info({"active_item_ids", ...}) respectively.
  describe "MemberView search and filter" do
    setup ctx do
      owner = Factories.insert!(:creator)
      {:ok, ctx} = login(owner, ctx)
      conn = ctx[:conn] |> Map.put(:request_path, "/org/node")

      org =
        Factories.insert!(:org_node, %{
          identifier: ["user_view_filter_test_org"],
          domains: ["filter-test.org"]
        })

      :ok = Org.Public.assign_owner(org, owner)

      context =
        LiveContext.new(%{
          node_id: org.id,
          current_user: owner,
          locale: :en
        })

      {:ok, conn: conn, org: org, context: context}
    end

    test ":external filter via Selector handle_info narrows the rendered list",
         %{conn: conn, org: org, context: context} do
      internal = Factories.insert!(:creator, %{email: "alice@filter-test.org"})
      external = Factories.insert!(:creator, %{email: "alice@elsewhere.example"})
      Org.Public.add_member(org, internal)
      Org.Public.add_member(org, external)

      {:ok, view, html} =
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

      assert html =~ internal.email
      assert html =~ external.email

      send(view.pid, {"active_item_ids", %{active_item_ids: [:external]}})

      rendered = render(view)
      assert rendered =~ external.email
      refute rendered =~ internal.email
    end

    test "search query via SearchBar consume_event narrows the rendered list",
         %{conn: conn, org: org, context: context} do
      match = Factories.insert!(:creator, %{email: "needle@filter-test.org"})
      other = Factories.insert!(:creator, %{email: "haystack@filter-test.org"})
      Org.Public.add_member(org, match)
      Org.Public.add_member(org, other)

      {:ok, view, html} =
        live_isolated(conn, Org.MemberView, session: %{"live_context" => context})

      assert html =~ match.email
      assert html =~ other.email

      send(
        view.pid,
        {:live_nest_event,
         %LiveNest.Event{
           name: :search_query,
           payload: %{query: ["needle"], query_string: "needle"},
           source: {self(), nil}
         }}
      )

      rendered = render(view)
      assert rendered =~ match.email
      refute rendered =~ other.email
    end
  end
end
