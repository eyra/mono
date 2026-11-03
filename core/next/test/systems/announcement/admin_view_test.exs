defmodule Systems.Announcement.AdminViewTest do
  use CoreWeb.ConnCase, async: false
  use Core.FeatureFlags.Test
  use Oban.Testing, repo: Core.Repo

  import Ecto.Query, only: [from: 2]
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

  defp published!(admin) do
    {:ok, announcement} =
      Announcement.Public.create_announcement(admin, %{
        kind: :release_notes,
        title: "Published",
        summary: "Summary",
        body: "<div>Text</div>"
      })

    {:ok, published} = Announcement.Public.publish_announcement(announcement, [], nil, 2)
    published
  end

  defp stored_recipient_ids do
    Repo.all(from(a in Announcement.Model, select: a.recipient_ids))
  end

  # Sends the count on the Publish button, as the browser does ("0" when there
  # is no button).
  defp publish(view, attrs, body), do: publish(view, attrs, body, shown_count(view))

  defp publish(view, attrs, body, shown_count) do
    render_submit(view, "save_announcement", %{
      "announcement" => attrs,
      "announcement[body]_input" => body,
      "publish" => shown_count
    })
  end

  defp shown_count(view) do
    view
    |> render()
    |> Floki.parse_document!()
    |> Floki.attribute("button[data-testid='publish-announcement-button']", "value")
    |> List.first("0")
  end

  defp search(view, query) do
    view
    |> element("#announcement_audience_search_form")
    |> render_change(%{"query" => query})
  end

  defp toggle_filter(view, filter) do
    render_click(view, "toggle_audience_filter", %{"filter" => filter})
  end

  defp recipient_count_text(view) do
    view |> element("[data-testid='announcement-recipient-count']") |> render()
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
          ~s|<div>See <a href="https://eyra.co">the notes</a></div>|
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

    test "every link opens in a new tab, whatever target it had", %{conn: conn, admin: admin} do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")

      save(
        view,
        @attrs,
        ~s|<div><a href="https://a.org" target="_self">a</a> | <>
          ~s|<a href='https://b.org' TARGET=_top target="_parent">b</a> | <>
          ~s|<a href="https://c.org" target="_blank">c</a> <a href="https://d.org">d</a></div>|
      )

      assert [%Announcement.Model{body: body}] = Repo.all(Announcement.Model)

      assert body ==
               ~s|<div><a href="https://a.org" target="_blank">a</a> | <>
                 ~s|<a href='https://b.org' target="_blank">b</a> | <>
                 ~s|<a href="https://c.org" target="_blank">c</a> | <>
                 ~s|<a href="https://d.org" target="_blank">d</a></div>|
    end

    test "a link with a data-target attribute opens in a new tab too", %{
      conn: conn,
      admin: admin
    } do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")

      save(view, @attrs, ~s|<div><a href="https://a.org" data-target="menu">a</a></div>|)

      assert [%Announcement.Model{body: body}] = Repo.all(Announcement.Model)

      assert body ==
               ~s|<div><a href="https://a.org" data-target="menu" target="_blank">a</a></div>|
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

  describe "publishing" do
    setup do
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      %{
        admin: Factories.insert!(:admin),
        verified: Factories.insert!(:creator, %{email: "anna@example.org", verified_at: now}),
        unverified: Factories.insert!(:creator, %{email: "bram@example.org"}),
        deactivated:
          Factories.insert!(:creator, %{email: "carla@example.org", confirmed_at: nil}),
        member: Factories.insert!(:member, %{email: "dirk@example.org"})
      }
    end

    test "the form shows the audience, the count and whether email is sent", %{
      conn: conn,
      admin: admin
    } do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")

      assert has_element?(view, "[data-testid='announcement-audience']", "Creators")
      assert recipient_count_text(view) =~ "2 creators will receive this announcement."
      assert has_element?(view, "[data-testid='announcement-email-notice']", "No email is sent.")
      assert has_element?(view, "button[data-testid='publish-announcement-button']")
    end

    test "choosing high priority says an email is sent", %{conn: conn, admin: admin} do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")

      render_change(view, "change_announcement", %{"announcement" => %{"priority" => "high"}})

      assert has_element?(
               view,
               "[data-testid='announcement-email-notice']",
               "Each recipient also gets an email."
             )
    end

    test "Verified narrows the count", %{conn: conn, admin: admin} do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")

      toggle_filter(view, "verified")

      assert recipient_count_text(view) =~ "1 creator will receive this announcement."
    end

    test "a chosen filter is shown as chosen", %{conn: conn, admin: admin} do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")

      toggle_filter(view, "verified")

      assert has_element?(view, "[data-testid='audience-filter-verified'] .bg-primary")
      refute has_element?(view, "[data-testid='audience-filter-unverified'] .bg-primary")
    end

    test "choosing a filter again drops it", %{conn: conn, admin: admin} do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")

      toggle_filter(view, "verified")
      toggle_filter(view, "verified")

      assert recipient_count_text(view) =~ "2 creators will receive this announcement."
    end

    test "the participant filters can't be chosen", %{conn: conn, admin: admin} do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")

      refute has_element?(view, "[data-testid='audience-filter-affiliate']")
      toggle_filter(view, "affiliate")

      assert recipient_count_text(view) =~ "2 creators will receive this announcement."
    end

    test "search narrows the count", %{conn: conn, admin: admin} do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")

      search(view, "bram")

      assert recipient_count_text(view) =~ "1 creator will receive this announcement."
    end

    test "publishes to the chosen audience and lists it with its recipient count", %{
      conn: conn,
      admin: admin,
      unverified: unverified
    } do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")
      toggle_filter(view, "unverified")

      publish(view, @attrs, "<div>Text</div>")

      assert [%Announcement.Model{id: id, published_at: %DateTime{}}] =
               Repo.all(Announcement.Model)

      assert stored_recipient_ids() == [[unverified.id]]
      assert_enqueued(worker: Announcement.DeliverJob, args: %{"announcement_id" => id})

      refute has_element?(view, "[data-testid='announcement-form']")
      assert view |> element("[data-testid='announcement-row-#{id}']") |> render() =~ "<td>1</td>"
    end

    test "the browser can't choose the recipients", %{
      conn: conn,
      admin: admin,
      verified: verified,
      member: member
    } do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")
      toggle_filter(view, "verified")

      publish(
        view,
        Map.merge(@attrs, %{"recipient_ids" => [member.id], "published_at" => "2020-01-01"}),
        "<div>Text</div>"
      )

      assert stored_recipient_ids() == [[verified.id]]
    end

    test "with nobody in the audience, Publish says what to change and publishes nothing", %{
      conn: conn,
      admin: admin
    } do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")
      search(view, "nobody")

      assert has_element?(view, "button[data-testid='publish-announcement-button'][value='0']")
      refute has_element?(view, "[data-testid='publish-announcement-button'][disabled]")
      assert recipient_count_text(view) =~ "No creators match"
      refute has_element?(view, "[data-testid='announcement-compose-notice']")

      publish(view, @attrs, "<div>Text</div>")

      assert [%Announcement.Model{published_at: nil}] = Repo.all(Announcement.Model)
      refute_enqueued(worker: Announcement.DeliverJob)
      assert has_element?(view, "[data-testid='announcement-form']")

      assert has_element?(
               view,
               "[data-testid='announcement-compose-notice']",
               "No creators match these filters and search, so nothing was published. " <>
                 "Change the filters or search and press Publish again."
             )

      publish(view, %{@attrs | "title" => "Changed"}, "<div>Text</div>")
      assert [%Announcement.Model{title: "Changed"}] = Repo.all(Announcement.Model)
    end

    test "changing the audience after a refused Publish drops the notice", %{
      conn: conn,
      admin: admin
    } do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")
      search(view, "nobody")
      publish(view, @attrs, "<div>Text</div>")
      assert has_element?(view, "[data-testid='announcement-compose-notice']")

      search(view, "bram")

      refute has_element?(view, "[data-testid='announcement-compose-notice']")
      assert recipient_count_text(view) =~ "1 creator will receive this announcement."
    end

    test "when the audience emptied since it was shown, nothing is published", %{
      conn: conn,
      admin: admin,
      unverified: unverified
    } do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")
      search(view, "bram")
      assert recipient_count_text(view) =~ "1 creator will receive this announcement."

      unverified |> Ecto.Changeset.change(confirmed_at: nil) |> Repo.update!()
      publish(view, @attrs, "<div>Text</div>", "1")

      assert [%Announcement.Model{published_at: nil}] = Repo.all(Announcement.Model)
      refute_enqueued(worker: Announcement.DeliverJob)
      assert recipient_count_text(view) =~ "No creators match"

      assert has_element?(
               view,
               "[data-testid='announcement-compose-notice']",
               "so nothing was published"
             )
    end

    test "a saved announcement is opened again and published", %{conn: conn, admin: admin} do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")
      save(view, @attrs, "<div>Text</div>")

      assert [%Announcement.Model{id: id, published_at: nil}] = Repo.all(Announcement.Model)
      assert has_element?(view, "[data-testid='edit-announcement-#{id}']")

      render_click(view, "edit_announcement", %{"item" => to_string(id)})
      assert render(view) =~ ~s(value="March release")
      refute has_element?(view, "[data-testid='edit-announcement-#{id}']")

      publish(view, %{@attrs | "title" => "April release"}, "<div>Text</div>")

      assert [%Announcement.Model{id: ^id, title: "April release", published_at: %DateTime{}}] =
               Repo.all(Announcement.Model)

      refute has_element?(view, "[data-testid='announcement-form']")
      assert has_element?(view, "[data-testid='edit-announcement-#{id}']")
    end

    test "a published announcement opens with only its title, summary and body", %{
      conn: conn,
      admin: admin
    } do
      %{id: id} = published!(admin)

      view = mount_view(conn, admin)
      assert has_element?(view, "[data-testid='edit-announcement-#{id}']")
      render_click(view, "edit_announcement", %{"item" => to_string(id)})

      html = view |> element("[data-testid='announcement-form']") |> render()
      assert html =~ ~s(value="Published")
      assert html =~ ~s(value="Summary")
      refute html =~ ~s(name="announcement[priority]")
      refute html =~ ~s(name="announcement[kind]")

      refute has_element?(view, "[data-testid='announcement-audience']")
      refute has_element?(view, "[data-testid='publish-announcement-button']")
      assert has_element?(view, "[data-testid='save-announcement-button']")

      assert has_element?(
               view,
               "[data-testid='announcement-published-notice']",
               "This announcement is published. Saving shows your changes to its recipients " <>
                 "at once; it isn't sent again."
             )
    end

    test "saving a published announcement changes its text and sends nothing again", %{
      conn: conn,
      admin: admin
    } do
      %{id: id, published_at: published_at} = published!(admin)
      enqueued = all_enqueued()

      view = mount_view(conn, admin)
      render_click(view, "edit_announcement", %{"item" => to_string(id)})

      save(
        view,
        %{"title" => "Published, corrected", "summary" => "Summary, corrected"},
        ~s|<div>See <a href="https://eyra.co/v2">the notes</a></div>|
      )

      assert [
               %Announcement.Model{
                 id: ^id,
                 title: "Published, corrected",
                 summary: "Summary, corrected",
                 priority: :normal,
                 published_at: ^published_at
               } = announcement
             ] = Repo.all(Announcement.Model)

      assert announcement.body ==
               ~s(<div>See <a href="https://eyra.co/v2" target="_blank">the notes</a></div>)

      assert all_enqueued() == enqueued
      refute has_element?(view, "[data-testid='announcement-form']")
      assert has_element?(view, "[data-testid='announcement-row-#{id}']", "Published, corrected")
    end

    test "a second form doesn't undo a correction saved in a first form", %{
      conn: conn,
      admin: admin
    } do
      %{id: id} = published!(admin)
      first = mount_view(conn, admin)
      second = mount_view(conn, admin)

      for view <- [first, second] do
        render_click(view, "edit_announcement", %{"item" => to_string(id)})
      end

      save(first, %{"title" => "Published, corrected", "summary" => "Summary"}, "<div>Text</div>")
      save(second, %{"title" => "Published", "summary" => "Summary"}, "<div>Text, fixed</div>")

      assert [%Announcement.Model{title: "Published, corrected", body: "<div>Text</div>"}] =
               Repo.all(Announcement.Model)

      assert has_element?(second, "[data-testid='announcement-form']")

      assert has_element?(
               second,
               "[data-testid='announcement-compose-notice']",
               "This announcement was changed in the meantime, so your changes were not saved."
             )
    end

    test "a published announcement keeps its priority", %{conn: conn, admin: admin} do
      %{id: id} = published!(admin)

      view = mount_view(conn, admin)
      render_click(view, "edit_announcement", %{"item" => to_string(id)})
      save(view, %{"title" => "Changed", "priority" => "high"}, "<div>Text</div>")

      assert [%Announcement.Model{title: "Published", priority: :normal}] =
               Repo.all(Announcement.Model)

      assert has_element?(view, "[data-testid='announcement-form']")
    end

    test "Publish sends the count the admin sees", %{conn: conn, admin: admin} do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")

      assert has_element?(view, "button[data-testid='publish-announcement-button'][value='2']")
      toggle_filter(view, "verified")
      assert has_element?(view, "button[data-testid='publish-announcement-button'][value='1']")
    end

    test "when the audience changed since it was shown, nothing is published", %{
      conn: conn,
      admin: admin
    } do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")
      assert recipient_count_text(view) =~ "2 creators will receive this announcement."

      Factories.insert!(:creator, %{email: "eva@example.org"})
      publish(view, @attrs, "<div>Text</div>", "2")

      assert [%Announcement.Model{published_at: nil}] = Repo.all(Announcement.Model)
      refute_enqueued(worker: Announcement.DeliverJob)
      assert has_element?(view, "[data-testid='announcement-form']")
      assert recipient_count_text(view) =~ "3 creators will receive this announcement."

      assert has_element?(
               view,
               "[data-testid='announcement-compose-notice']",
               "The audience changed to 3 creators. Press Publish again to send it."
             )
    end

    test "after the audience changed, Publish again publishes to the new count", %{
      conn: conn,
      admin: admin
    } do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")
      Factories.insert!(:creator, %{email: "eva@example.org"})
      publish(view, @attrs, "<div>Text</div>", "2")

      publish(view, @attrs, "<div>Text</div>")

      assert [%Announcement.Model{published_at: %DateTime{}}] = Repo.all(Announcement.Model)
      assert [ids] = stored_recipient_ids()
      assert length(ids) == 3
      refute has_element?(view, "[data-testid='announcement-form']")
    end

    test "a form opened before the announcement was published doesn't change it on Save", %{
      conn: conn,
      admin: admin
    } do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")
      save(view, @attrs, "<div>Text</div>")
      [%Announcement.Model{id: id} = announcement] = Repo.all(Announcement.Model)

      render_click(view, "edit_announcement", %{"item" => to_string(id)})
      {:ok, _} = Announcement.Public.publish_announcement(announcement, [], nil, 2)

      save(
        view,
        %{@attrs | "title" => "Changed after publish", "priority" => "normal"},
        "<div>X</div>"
      )

      assert [
               %Announcement.Model{
                 title: "March release",
                 priority: :high,
                 body: "<div>Text</div>"
               }
             ] =
               Repo.all(Announcement.Model)

      assert has_element?(view, "[data-testid='announcement-form']")

      assert has_element?(
               view,
               "[data-testid='announcement-compose-notice']",
               "This announcement was published in the meantime, so your changes were not saved."
             )
    end

    test "a form opened before the announcement was published doesn't change it on Publish", %{
      conn: conn,
      admin: admin
    } do
      view = mount_view(conn, admin)
      render_click(view, "new_announcement")
      save(view, @attrs, "<div>Text</div>")
      [%Announcement.Model{id: id} = announcement] = Repo.all(Announcement.Model)

      render_click(view, "edit_announcement", %{"item" => to_string(id)})
      toggle_filter(view, "verified")
      {:ok, _} = Announcement.Public.publish_announcement(announcement, [], nil, 2)

      publish(view, %{@attrs | "title" => "Changed after publish"}, "<div>X</div>")

      assert [%Announcement.Model{title: "March release"}] = Repo.all(Announcement.Model)
      assert [[_, _]] = stored_recipient_ids()
      assert [_] = all_enqueued(worker: Announcement.DeliverJob)

      assert has_element?(
               view,
               "[data-testid='announcement-compose-notice']",
               "published in the meantime"
             )
    end

    test "an org admin can't publish", %{conn: conn} do
      user = Factories.insert!(:member)
      make_org_admin(user)
      view = mount_view(conn, user)

      publish(view, @attrs, "<div>Text</div>")

      assert announcement_count() == 0
      refute_enqueued(worker: Announcement.DeliverJob)
    end
  end
end
