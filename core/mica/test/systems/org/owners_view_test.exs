defmodule Systems.Org.OwnersViewTest do
  use CoreWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Systems.Org

  describe "OwnersView" do
    setup ctx do
      user = Factories.insert!(:member)
      {:ok, ctx} = login(user, ctx)
      conn = ctx[:conn] |> Map.put(:request_path, "/org/owners")
      {:ok, conn: conn, user: user}
    end

    test "renders owners list", %{conn: conn} do
      owner1 = Factories.insert!(:member)
      owner2 = Factories.insert!(:member)
      org = Factories.insert!(:org_node, %{identifier: ["owners_view_org"]})

      Core.Authorization.assign_role(owner1, org, :owner)
      Core.Authorization.assign_role(owner2, org, :owner)

      {:ok, view, _html} =
        live_isolated(conn, Org.OwnersView,
          session: %{
            "node_id" => org.id
          }
        )

      assert has_element?(view, "div", owner1.displayname)
      assert has_element?(view, "div", owner1.email)
      assert has_element?(view, "div", owner2.displayname)
      assert has_element?(view, "div", owner2.email)
    end

    test "renders empty message when no owners", %{conn: conn} do
      org = Factories.insert!(:org_node, %{identifier: ["no_owners_view_org"]})

      {:ok, _view, html} =
        live_isolated(conn, Org.OwnersView,
          session: %{
            "node_id" => org.id
          }
        )

      assert html =~ "No admins assigned yet"
    end
  end
end
