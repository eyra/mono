defmodule Systems.Admin.SystemViewTest do
  use CoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Frameworks.Concept.LiveContext
  alias Systems.Admin

  describe "SystemView" do
    setup ctx do
      user = Factories.insert!(:member)
      {:ok, ctx} = login(user, ctx)
      conn = Map.put(ctx[:conn], :request_path, "/admin/system")

      context =
        LiveContext.new(%{
          current_user: user,
          locale: :en,
          bank_accounts: [],
          bank_account_items: [],
          citizen_pools: [],
          citizen_pool_items: []
        })

      {:ok, conn: conn, user: user, context: context}
    end

    test "renders system view", %{conn: conn, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.SystemView, session: %{"live_context" => context})

      assert has_element?(view, "[data-testid='system-view']")
    end

    test "renders bank accounts section", %{conn: conn, context: context} do
      {:ok, _view, html} =
        live_isolated(conn, Admin.SystemView, session: %{"live_context" => context})

      assert html =~ "Bank accounts"
    end

    test "renders citizen pools section", %{conn: conn, context: context} do
      {:ok, _view, html} =
        live_isolated(conn, Admin.SystemView, session: %{"live_context" => context})

      assert html =~ "Citizen pools"
    end

    test "create_bank_account event presents modal", %{conn: conn, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.SystemView, session: %{"live_context" => context})

      _ = render_click(view, "create_bank_account")

      assert has_element?(view, "[data-testid='system-view']")
    end

    test "create_citizen_pool event presents modal", %{conn: conn, context: context} do
      {:ok, view, _html} =
        live_isolated(conn, Admin.SystemView, session: %{"live_context" => context})

      _ = render_click(view, "create_citizen_pool")

      assert has_element?(view, "[data-testid='system-view']")
    end

    test "edit_bank_account event presents modal", %{conn: conn, user: user} do
      bank_account =
        Factories.insert!(:bank_account, %{name: "Test Bank", icon: {:static, "bank"}})

      context =
        LiveContext.new(%{
          current_user: user,
          locale: :en,
          bank_accounts: [bank_account],
          bank_account_items: [],
          citizen_pools: [],
          citizen_pool_items: []
        })

      {:ok, view, _html} =
        live_isolated(conn, Admin.SystemView, session: %{"live_context" => context})

      _ = render_click(view, "edit_bank_account", %{"item" => "#{bank_account.id}"})

      assert has_element?(view, "[data-testid='system-view']")
    end

    test "edit_citizen_pool event presents modal", %{conn: conn, user: user} do
      pool =
        Factories.insert!(:pool, %{name: "Test Pool", icon: {:static, "pool"}, director: :citizen})

      context =
        LiveContext.new(%{
          current_user: user,
          locale: :en,
          bank_accounts: [],
          bank_account_items: [],
          citizen_pools: [pool],
          citizen_pool_items: []
        })

      {:ok, view, _html} =
        live_isolated(conn, Admin.SystemView, session: %{"live_context" => context})

      _ = render_click(view, "edit_citizen_pool", %{"item" => "#{pool.id}"})

      assert has_element?(view, "[data-testid='system-view']")
    end
  end
end
