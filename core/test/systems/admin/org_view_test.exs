defmodule Systems.Admin.OrgViewTest do
  use CoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Frameworks.Concept.LiveContext
  alias Systems.Admin
  alias Systems.NextAction.Public
  alias Systems.Org
  alias Systems.Org.NextActions.AddDomainMembers

  describe "OrgView" do
    setup ctx do
      user = Factories.insert!(:member)
      {:ok, ctx} = login(user, ctx)

      {:ok, %{org: org}} =
        Org.Public.create_node(
          ["view", "test"],
          [{:en, "VIEW"}, {:nl, "VIEW"}],
          [{:en, "View Test Org"}, {:nl, "View Test Org"}]
        )

      org = Org.Public.get_node!(org.id, Org.NodeModel.preload_graph(:full))

      context =
        LiveContext.new(%{
          current_user: user,
          locale: :en,
          is_admin?: true,
          governable_orgs: [org]
        })

      conn = Map.put(ctx[:conn], :request_path, "/admin/orgs")

      {:ok, conn: conn, user: user, org: org, context: context}
    end

    test "renders org view", %{conn: conn, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      assert has_element?(view, "[data-testid='org-view']")
    end

    test "renders title", %{conn: conn, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      assert has_element?(view, "[data-testid='org-title']")
    end

    test "handle_item_click redirects to org page", %{conn: conn, org: org, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      assert {:error, {:live_redirect, %{to: path}}} =
               render_click(view, "handle_item_click", %{"item" => org.id})

      assert path == "/org/node/#{org.id}"
    end

    test "create_org event creates new org and navigates", %{conn: conn, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      assert {:error, {:live_redirect, %{to: path}}} = render_click(view, "create_org")

      assert path =~ "/org/node/"
    end

    test "card_clicked navigates to org", %{conn: conn, org: org, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      assert {:error, {:live_redirect, %{to: path}}} =
               render_click(view, "card_clicked", %{"item" => org.id})

      assert path == "/org/node/#{org.id}"
    end

    test "archive_org archives organisation", %{conn: conn, org: org, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      _ = render_click(view, "archive_org", %{"item" => "#{org.id}"})

      updated_org = Org.Public.get_node!(org.id)
      assert updated_org.archived_at
    end

    test "setup_admins presents modal", %{conn: conn, org: org, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      _ = render_click(view, "setup_admins", %{"item" => "#{org.id}"})

      assert has_element?(view, "[data-testid='org-view']")
    end

    test "show_archived presents modal", %{conn: conn, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      _ = render_click(view, "show_archived")

      assert has_element?(view, "[data-testid='org-view']")
    end

    # Regression coverage for FX#9905887344 — the AddDomainMembers banner
    # on Admin.OrgView must disappear without a manual refresh when the
    # NextAction is cleared (e.g. because the user's :owner role was
    # revoked in another session).
    test "AddDomainMembers banner disappears live when the NextAction is cleared",
         %{conn: conn, user: user, org: org, context: context} do
      Public.create_next_action(
        user,
        AddDomainMembers,
        key: "org:#{org.id}",
        params: %{org_id: org.id, org_name: "Test Org", domains: "test-domain.test"}
      )

      {:ok, view, html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      assert html =~ "Manage members"

      Public.clear_next_action(
        user,
        AddDomainMembers,
        key: "org:#{org.id}"
      )

      refute render(view) =~ "Manage members"
    end
  end
end
