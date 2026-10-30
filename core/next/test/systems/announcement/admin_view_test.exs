defmodule Systems.Announcement.AdminViewTest do
  use CoreWeb.ConnCase, async: false
  use Core.FeatureFlags.Test

  import Phoenix.LiveViewTest

  alias Core.Repo
  alias Systems.Announcement

  @attrs %{
    "kind" => "release_notes",
    "title" => "March release",
    "summary" => "What changed",
    "priority" => "high"
  }

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

  defp save(view, attrs, body) do
    render_submit(view, "save_announcement", %{
      "announcement" => attrs,
      "announcement[body]_input" => body
    })
  end

  # Two orgs, so the Admin page does not redirect to the only one.
  defp make_org_admin(user) do
    for name <- ["first", "second"] do
      {:ok, %{org: org}} =
        Systems.Org.Public.create_node(["announcements", name], [{:en, name}], [{:en, name}])

      Core.Authorization.assign_role(user, org, :owner)
    end
  end

  defp announcement_count, do: Repo.aggregate(Announcement.Model, :count)

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
  end

  describe "system admin" do
    setup do
      %{admin: Factories.insert!(:admin)}
    end

    test "sees the list and composes an announcement", %{conn: conn, admin: admin} do
      view = mount_view(conn, admin)

      assert render(view) =~ "No announcements yet."
      refute has_element?(view, "[data-testid='announcement-form']")

      assert has_element?(view, "[data-testid='new-announcement-button']")
      render_click(view, "new_announcement")
      assert has_element?(view, "[data-testid='announcement-form']")

      html =
        save(
          view,
          @attrs,
          ~s|<div>See <a href="https://eyra.co">the notes</a><script>alert(1)</script></div>|
        )

      assert [%Announcement.Model{id: id} = announcement] = Repo.all(Announcement.Model)

      assert %{
               kind: :release_notes,
               title: "March release",
               summary: "What changed",
               priority: :high,
               published_at: nil,
               author_id: author_id
             } = announcement

      assert author_id == admin.id

      assert announcement.body ==
               ~s(<div>See <a href="https://eyra.co" target="_blank">the notes</a></div>)

      refute has_element?(view, "[data-testid='announcement-form']")
      assert has_element?(view, "[data-testid='announcement-row-#{id}']", "March release")
      assert html =~ "Not published"
    end

    test "cancel closes the form", %{conn: conn, admin: admin} do
      view = mount_view(conn, admin)

      render_click(view, "new_announcement")
      assert has_element?(view, "[data-testid='announcement-form']")

      render_click(view, "cancel_announcement")
      refute has_element?(view, "[data-testid='announcement-form']")
    end

    test "a body without text is refused", %{conn: conn, admin: admin} do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")

      html = save(view, @attrs, ~s(<div><figure><img src="https://eyra.co/a.png"></figure></div>))

      assert announcement_count() == 0
      assert has_element?(view, "[data-testid='announcement-form']")
      assert html =~ "Please fill out this field"
    end

    test "a title over 255 characters is refused", %{conn: conn, admin: admin} do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")

      html = save(view, %{@attrs | "title" => String.duplicate("a", 256)}, "<div>Text</div>")

      assert announcement_count() == 0
      assert html =~ "should be at most 255 character(s)"
    end

    test "events do nothing when the flag is off", %{conn: conn, admin: admin} do
      set_feature_flag(:announcements, false)
      view = mount_view(conn, admin)

      refute has_element?(view, "[data-testid='new-announcement-button']")
      render_click(view, "new_announcement")
      refute has_element?(view, "[data-testid='announcement-form']")

      save(view, @attrs, "<div>Text</div>")
      assert announcement_count() == 0
    end
  end

  describe "other users" do
    for role <- [:creator, :member] do
      test "a #{role} sees nothing and its events do nothing", %{conn: conn} do
        user = Factories.insert!(unquote(role))

        Factories.insert!(:admin)
        |> Announcement.Public.create_announcement(%{
          kind: :release_notes,
          title: "Existing",
          summary: "Summary",
          body: "<div>Text</div>",
          priority: :normal
        })

        view = mount_view(conn, user)

        refute render(view) =~ "Existing"
        refute has_element?(view, "[data-testid='new-announcement-button']")

        render_click(view, "new_announcement")
        refute has_element?(view, "[data-testid='announcement-form']")

        save(view, @attrs, "<div>Text</div>")
        assert announcement_count() == 1
      end
    end

    test "an org admin's events do nothing", %{conn: conn} do
      user = Factories.insert!(:member)

      make_org_admin(user)

      view = mount_view(conn, user)

      render_click(view, "new_announcement")
      refute has_element?(view, "[data-testid='announcement-form']")

      save(view, @attrs, "<div>Text</div>")
      assert announcement_count() == 0
    end
  end
end
