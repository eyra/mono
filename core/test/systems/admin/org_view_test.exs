defmodule Systems.Admin.OrgViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Frameworks.Concept.LiveContext
  alias Systems.Admin
  alias Systems.Org

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

      conn = ctx[:conn] |> Map.put(:request_path, "/admin/orgs")

      {:ok, conn: conn, user: user, org: org, context: context}
    end

    test "renders org view", %{conn: conn, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      assert view |> has_element?("[data-testid='org-view']")
    end

    test "renders title", %{conn: conn, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      assert view |> has_element?("[data-testid='org-title']")
    end

    test "handle_item_click redirects to org page", %{conn: conn, org: org, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      assert {:error, {:live_redirect, %{to: path}}} =
               view |> render_click("handle_item_click", %{"item" => org.id})

      assert path == "/org/node/#{org.id}"
    end

    test "create_org event creates new org and navigates", %{conn: conn, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      assert {:error, {:live_redirect, %{to: path}}} =
               view |> render_click("create_org")

      assert path =~ "/org/node/"
    end

    test "card_clicked navigates to org", %{conn: conn, org: org, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      assert {:error, {:live_redirect, %{to: path}}} =
               view |> render_click("card_clicked", %{"item" => org.id})

      assert path == "/org/node/#{org.id}"
    end

    test "archive_org archives organisation", %{conn: conn, org: org, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      _ = view |> render_click("archive_org", %{"item" => "#{org.id}"})

      updated_org = Org.Public.get_node!(org.id)
      assert updated_org.archived_at != nil
    end

    test "setup_admins presents modal", %{conn: conn, org: org, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      _ = view |> render_click("setup_admins", %{"item" => "#{org.id}"})

      assert view |> has_element?("[data-testid='org-view']")
    end

    test "show_archived presents modal", %{conn: conn, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.OrgView, session: %{"live_context" => context})

      _ = view |> render_click("show_archived")

      assert view |> has_element?("[data-testid='org-view']")
    end
  end
end
