defmodule Systems.Org.AdminsModalViewTest do
  use CoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Core.Factories
  alias Systems.Org

  describe "AdminsModalView" do
    setup ctx do
      user = Factories.insert!(:creator)
      {:ok, ctx} = login(user, ctx)
      conn = ctx[:conn] |> Map.put(:request_path, "/org/admins")
      {:ok, conn: conn, user: user}
    end

    test "renders modal with title", %{conn: conn} do
      org = Factories.insert!(:org_node, %{identifier: ["admins_modal_org"]})

      {:ok, view, _html} =
        live_isolated(conn, Org.AdminsModalView,
          session: %{
            "org_id" => org.id,
            "locale" => "en"
          }
        )

      assert has_element?(view, "[data-testid='org-admins-modal']")
    end

    test "handle_info add_user assigns owner role", %{conn: conn, user: _user} do
      new_owner = Factories.insert!(:creator)
      org = Factories.insert!(:org_node, %{identifier: ["add_owner_org"]})

      {:ok, view, _html} =
        live_isolated(conn, Org.AdminsModalView,
          session: %{
            "org_id" => org.id,
            "locale" => "en"
          }
        )

      # Initially no owners
      assert Enum.empty?(Org.Public.list_owners(org))

      # Send add_user info
      send(view.pid, {:add_user, %{user: new_owner}})

      # Wait for the message to be processed
      _ = render(view)

      # Now the user should be an owner
      owners = Org.Public.list_owners(org)
      assert length(owners) == 1
      assert hd(owners).id == new_owner.id
    end

    test "handle_info remove_user revokes owner role", %{conn: conn, user: _user} do
      owner = Factories.insert!(:creator)
      org = Factories.insert!(:org_node, %{identifier: ["remove_owner_org"]})
      Core.Authorization.assign_role(owner, org, :owner)

      {:ok, view, _html} =
        live_isolated(conn, Org.AdminsModalView,
          session: %{
            "org_id" => org.id,
            "locale" => "en"
          }
        )

      # Initially has one owner
      assert length(Org.Public.list_owners(org)) == 1

      # Send remove_user info
      send(view.pid, {:remove_user, %{user: owner}})

      # Wait for the message to be processed
      _ = render(view)

      # Now no owners
      assert Enum.empty?(Org.Public.list_owners(org))
    end
  end
end
