defmodule Next.Systems.Announcement.AdminViewTest do
  use MicaWeb.ConnCase, async: false
  use NextWeb, :verified_routes
  use Mica.FeatureFlags.Test

  import Phoenix.LiveViewTest

  alias Next.Systems.Announcement

  setup do
    set_feature_flag(:announcements, true)
    :ok
  end

  defp mount_view(conn, user) do
    {:ok, view, _html} =
      conn
      |> Map.put(:request_path, "/admin/config")
      |> live_isolated(Announcement.AdminView, session: %{"user" => user})

    view
  end

  # Two orgs, so the Admin page does not redirect to the only one.
  defp make_org_admin(user) do
    for name <- ["first", "second"] do
      {:ok, %{org: org}} =
        Systems.Org.Public.create_node(["announcements", name], [{:en, name}], [{:en, name}])

      Mica.Authorization.assign_role(user, org, :owner)
    end
  end

  defp create!(author, title) do
    {:ok, announcement} =
      Announcement.Public.create_announcement(author, %{
        kind: :release_notes,
        title: title,
        summary: "Summary",
        body: "<div>Text</div>",
        priority: :normal
      })

    announcement
  end

  describe "Admin page" do
    test "shows the Announcements tab to a system admin", %{conn: conn} do
      {:ok, conn: conn, user: _admin} = login_as_admin(%{conn: conn})
      {:ok, view, _html} = live(conn, ~p"/admin/config")

      assert find_live_child(view, "admin_announcements_view")
    end

    test "has no Announcements tab when the flag is off", %{conn: conn} do
      set_feature_flag(:announcements, false)
      {:ok, conn: conn, user: _admin} = login_as_admin(%{conn: conn})
      {:ok, view, _html} = live(conn, ~p"/admin/config")

      assert find_live_child(view, "admin_system_view")
      refute find_live_child(view, "admin_announcements_view")
    end

    test "has no Announcements tab for an org admin", %{conn: conn} do
      {:ok, ctx} = login_as_member(%{conn: conn})
      conn = ctx[:conn]
      user = ctx[:user]

      make_org_admin(user)

      {:ok, view, _html} = live(conn, ~p"/admin/config")

      assert find_live_child(view, "admin_org_view")
      refute find_live_child(view, "admin_announcements_view")
    end

    test "a row in the Announcements tab opens the announcement", %{conn: conn} do
      {:ok, conn: conn, user: admin} = login_as_admin(%{conn: conn})
      %{id: id} = create!(admin, "March release")
      {:ok, view, _html} = live(conn, ~p"/admin/config")
      tab = find_live_child(view, "admin_announcements_view")

      tab |> element("[data-testid='announcement-row-#{id}']") |> render_click()

      assert {path, _flash} = assert_redirect(tab)
      assert path == "/admin/announcement/#{id}"
      {:ok, compose, _html} = live(conn, path)
      assert render(compose) =~ ~s(value="March release")
    end
  end

  describe "system admin" do
    setup do
      %{admin: Factories.insert!(:admin)}
    end

    test "sees that there are no announcements yet", %{conn: conn, admin: admin} do
      view = mount_view(conn, admin)

      assert render(view) =~ "No announcements yet."
      refute has_element?(view, "[data-testid='announcement-form']")
    end

    test "New announcement is a link to its own page", %{conn: conn, admin: admin} do
      view = mount_view(conn, admin)

      assert has_element?(
               view,
               "a[data-testid='new-announcement-button'][href='/admin/announcement/new']",
               "New announcement"
             )
    end

    test "every row opens its announcement; there is no Edit button", %{
      conn: conn,
      admin: admin
    } do
      %{id: first} = create!(admin, "March release")
      %{id: second} = create!(admin, "April release")
      view = mount_view(conn, admin)

      assert has_element?(view, "[data-testid='announcement-row-#{first}']", "March release")
      assert has_element?(view, "[data-testid='announcement-row-#{second}']", "April release")
      refute render(view) =~ "Edit"

      view |> element("[data-testid='announcement-row-#{second}']") |> render_click()
      assert_redirect(view, "/admin/announcement/#{second}")
    end

    test "shows nothing when the flag is off", %{conn: conn, admin: admin} do
      create!(admin, "Existing")
      set_feature_flag(:announcements, false)
      view = mount_view(conn, admin)

      refute render(view) =~ "Existing"
      refute has_element?(view, "[data-testid='new-announcement-button']")
    end
  end

  describe "other users" do
    for role <- [:creator, :member] do
      test "a #{role} sees nothing", %{conn: conn} do
        user = Factories.insert!(unquote(role))
        create!(Factories.insert!(:admin), "Existing")

        view = mount_view(conn, user)

        refute render(view) =~ "Existing"
        refute has_element?(view, "[data-testid='new-announcement-button']")
      end
    end

    test "an org admin sees nothing", %{conn: conn} do
      user = Factories.insert!(:member)
      make_org_admin(user)
      create!(Factories.insert!(:admin), "Existing")

      view = mount_view(conn, user)

      refute render(view) =~ "Existing"
      refute has_element?(view, "[data-testid='new-announcement-button']")
    end
  end
end
