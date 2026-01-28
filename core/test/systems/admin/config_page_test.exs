defmodule Systems.Admin.ConfigPageTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  describe "config page for system admin" do
    setup [:login_as_admin]

    test "render shows system admin tabs", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/config")
      assert html =~ "Admin"
      assert html =~ "System"
      assert html =~ "Organisations"
    end

    test "create bank account", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/config")

      system_view = find_live_child(view, "admin_system_view")
      render_click(system_view, "create_bank_account")

      # re-render for async popup
      assert render(view) =~ "Bank account"
    end

    test "create citizen pool", %{conn: conn} do
      Factories.insert!(:currency, %{name: "euro", type: :legal, decimal_scale: 2})

      {:ok, view, _html} = live(conn, ~p"/admin/config")

      system_view = find_live_child(view, "admin_system_view")
      render_click(system_view, "create_citizen_pool")

      # re-render for async popup
      assert render(view) =~ "New pool"
    end
  end

  describe "config page for creator with 0 orgs" do
    test "admin menu item is not shown", %{conn: conn} do
      user = Factories.insert!(:member, %{creator: true})

      {:ok, ctx} = Core.AuthTestHelpers.login(user, %{conn: conn})

      {:ok, _view, html} = live(ctx[:conn], ~p"/admin/config")

      # Admin menu item should NOT be visible (no orgs owned, not system admin)
      refute html =~ ~r/<a[^>]*href="\/admin\/config"[^>]*>.*Admin.*<\/a>/s
    end

    test "page shows empty content (no tabs)", %{conn: conn} do
      user = Factories.insert!(:member, %{creator: true})

      {:ok, ctx} = Core.AuthTestHelpers.login(user, %{conn: conn})

      {:ok, _view, html} = live(ctx[:conn], ~p"/admin/config")

      # Should show Admin title but no org-specific content
      assert html =~ "Admin"
      # Should not show System tab (not admin)
      refute html =~ "System"
      # Should not show Organisations tab (no orgs to show)
      refute html =~ "Organisations"
    end
  end

  describe "config page for creator with 1 org" do
    test "admin menu item is shown", %{conn: conn} do
      user = Factories.insert!(:member, %{creator: true})

      org =
        Factories.insert!(:org_node, %{
          identifier: ["single_org_menu"],
          short_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "Menu Org"}]}),
          full_name_bundle:
            Factories.build(:text_bundle, %{items: [%{text: "Menu Organisation"}]})
        })

      Core.Authorization.assign_role(user, org, :owner)

      {:ok, ctx} = Core.AuthTestHelpers.login(user, %{conn: conn})

      # Follow redirect to org content page
      {:error, {:live_redirect, %{to: redirect_path}}} = live(ctx[:conn], ~p"/admin/config")
      {:ok, _view, html} = live(ctx[:conn], redirect_path)

      # Admin menu item should be visible (owns an org)
      assert html =~ ~r/<a[^>]*href="\/admin\/config"[^>]*>/
    end

    test "redirects to org content page", %{conn: conn} do
      user = Factories.insert!(:member, %{creator: true})

      org =
        Factories.insert!(:org_node, %{
          identifier: ["single_org_redirect"],
          short_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "Single Org"}]}),
          full_name_bundle:
            Factories.build(:text_bundle, %{items: [%{text: "Single Organisation"}]})
        })

      Core.Authorization.assign_role(user, org, :owner)

      {:ok, ctx} = Core.AuthTestHelpers.login(user, %{conn: conn})

      # Should redirect to org content page
      {:error, {:live_redirect, %{to: redirect_path}}} = live(ctx[:conn], ~p"/admin/config")

      assert redirect_path == "/org/node/#{org.id}"
    end

    test "org content page shows single breadcrumb (no back link)", %{conn: conn} do
      user = Factories.insert!(:member, %{creator: true})

      org =
        Factories.insert!(:org_node, %{
          identifier: ["single_org_breadcrumb"],
          short_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "My Org"}]}),
          full_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "My Organisation"}]})
        })

      Core.Authorization.assign_role(user, org, :owner)

      {:ok, ctx} = Core.AuthTestHelpers.login(user, %{conn: conn})

      # Navigate directly to org content page
      {:ok, _view, html} = live(ctx[:conn], ~p"/org/node/#{org.id}")

      # Should show org name
      assert html =~ "My Organisation"
      # Should NOT have Admin breadcrumb link (single org = no back navigation needed)
      refute html =~ ~r/<a[^>]*href="\/admin\/config"[^>]*>Admin<\/a>/
    end
  end

  describe "config page for creator with 2+ orgs" do
    test "admin menu item is shown", %{conn: conn} do
      user = Factories.insert!(:member, %{creator: true})

      org1 =
        Factories.insert!(:org_node, %{
          identifier: ["multi_org_menu_one"],
          short_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "Menu One"}]}),
          full_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "Menu Org One"}]})
        })

      org2 =
        Factories.insert!(:org_node, %{
          identifier: ["multi_org_menu_two"],
          short_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "Menu Two"}]}),
          full_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "Menu Org Two"}]})
        })

      Core.Authorization.assign_role(user, org1, :owner)
      Core.Authorization.assign_role(user, org2, :owner)

      {:ok, ctx} = Core.AuthTestHelpers.login(user, %{conn: conn})

      {:ok, _view, html} = live(ctx[:conn], ~p"/admin/config")

      # Admin menu item should be visible (owns orgs)
      assert html =~ ~r/<a[^>]*href="\/admin\/config"[^>]*>/
    end

    test "shows organisations tab with filtered list", %{conn: conn} do
      user = Factories.insert!(:member, %{creator: true})

      org1 =
        Factories.insert!(:org_node, %{
          identifier: ["multi_org_one"],
          short_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "Org One"}]}),
          full_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "Organisation One"}]})
        })

      org2 =
        Factories.insert!(:org_node, %{
          identifier: ["multi_org_two"],
          short_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "Org Two"}]}),
          full_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "Organisation Two"}]})
        })

      Core.Authorization.assign_role(user, org1, :owner)
      Core.Authorization.assign_role(user, org2, :owner)

      {:ok, ctx} = Core.AuthTestHelpers.login(user, %{conn: conn})

      {:ok, _view, html} = live(ctx[:conn], ~p"/admin/config")

      # Should show Organisations tab
      assert html =~ "Organisations"
      # Should show both orgs the user owns
      assert html =~ "Organisation One"
      assert html =~ "Organisation Two"
      # Should NOT show System tab (not admin)
      refute html =~ "System"
    end

    test "org content page shows full breadcrumb with back link", %{conn: conn} do
      user = Factories.insert!(:member, %{creator: true})

      org1 =
        Factories.insert!(:org_node, %{
          identifier: ["breadcrumb_org_one"],
          short_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "First Org"}]}),
          full_name_bundle:
            Factories.build(:text_bundle, %{items: [%{text: "First Organisation"}]})
        })

      org2 =
        Factories.insert!(:org_node, %{
          identifier: ["breadcrumb_org_two"],
          short_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "Second Org"}]}),
          full_name_bundle:
            Factories.build(:text_bundle, %{items: [%{text: "Second Organisation"}]})
        })

      Core.Authorization.assign_role(user, org1, :owner)
      Core.Authorization.assign_role(user, org2, :owner)

      {:ok, ctx} = Core.AuthTestHelpers.login(user, %{conn: conn})

      # Navigate to first org content page
      {:ok, _view, html} = live(ctx[:conn], ~p"/org/node/#{org1.id}")

      # Should show org name
      assert html =~ "First Organisation"
      # Should have Admin breadcrumb link (multi-org = need back navigation)
      assert html =~ ~r/<a[^>]*href="\/admin\/config"[^>]*>/
    end

    test "does not show admin-only features like create org button", %{conn: conn} do
      user = Factories.insert!(:member, %{creator: true})

      org1 =
        Factories.insert!(:org_node, %{
          identifier: ["no_admin_features_one"],
          short_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "Org A"}]}),
          full_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "Organisation A"}]})
        })

      org2 =
        Factories.insert!(:org_node, %{
          identifier: ["no_admin_features_two"],
          short_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "Org B"}]}),
          full_name_bundle: Factories.build(:text_bundle, %{items: [%{text: "Organisation B"}]})
        })

      Core.Authorization.assign_role(user, org1, :owner)
      Core.Authorization.assign_role(user, org2, :owner)

      {:ok, ctx} = Core.AuthTestHelpers.login(user, %{conn: conn})

      {:ok, _view, html} = live(ctx[:conn], ~p"/admin/config")

      # Should NOT show create org button (admin-only)
      refute html =~ "create_org"
      # Should NOT show archive button (admin-only)
      refute html =~ "archive_org"
    end
  end
end
