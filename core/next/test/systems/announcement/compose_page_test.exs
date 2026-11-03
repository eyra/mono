defmodule Next.Systems.Announcement.ComposePageTest do
  use MicaWeb.ConnCase, async: false
  use Mica.FeatureFlags.Test
  use Oban.Testing, repo: Mica.Repo

  import Ecto.Query, only: [from: 2]
  import Phoenix.LiveViewTest

  alias Mica.Repo
  alias Next.Systems.Announcement

  @attrs %{
    "kind" => "release_notes",
    "title" => "March release",
    "summary" => "What changed",
    "priority" => "high"
  }

  @list_path "/admin/config?tab=announcements"

  setup %{conn: conn} do
    set_feature_flag(:announcements, true)
    {:ok, conn: conn, user: admin} = login_as_admin(%{conn: conn})
    %{conn: conn, admin: admin}
  end

  defp open_new(conn), do: open(conn, ~p"/admin/announcement/new")
  defp open_existing(conn, %{id: id}), do: open(conn, ~p"/admin/announcement/#{id}")

  defp open(conn, path) do
    {:ok, view, _html} = live(conn, path)
    view
  end

  defp save(view, attrs, body) do
    render_submit(view, "save_announcement", %{
      "announcement" => attrs,
      "announcement[body]_input" => body
    })
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

  defp announcement_count, do: Repo.aggregate(Announcement.Model, :count)

  defp draft!(admin) do
    {:ok, announcement} =
      Announcement.Public.create_announcement(admin, %{
        kind: :release_notes,
        title: "March release",
        summary: "What changed",
        body: "<div>Text</div>",
        priority: :high
      })

    announcement
  end

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

  defp sign_in(user) do
    {:ok, conn: conn, user: _user} = login(user, %{conn: MicaWeb.ConnCase.build_conn()})
    conn
  end

  # Two orgs, so the Admin page does not redirect to the only one.
  defp make_org_admin(user) do
    for name <- ["first", "second"] do
      {:ok, %{org: org}} =
        Systems.Org.Public.create_node(["announcements", name], [{:en, name}], [{:en, name}])

      Mica.Authorization.assign_role(user, org, :owner)
    end
  end

  describe "new announcement" do
    test "opens an empty form with the audience", %{conn: conn} do
      view = open_new(conn)

      assert has_element?(view, "[data-testid='announcement-compose-page']", "New announcement")
      assert has_element?(view, "[data-testid='announcement-form']")
      assert has_element?(view, "[data-testid='announcement-audience']")
      assert has_element?(view, "button[data-testid='publish-announcement-button']")
    end

    test "Save stores it unpublished and goes back to the list", %{conn: conn, admin: admin} do
      view = open_new(conn)

      save(view, @attrs, ~s|<div>See <a href="https://eyra.co">the notes</a></div>|)

      assert_redirect(view, @list_path)
      assert [%Announcement.Model{} = announcement] = Repo.all(Announcement.Model)

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
    end

    test "every link opens in a new tab, whatever target it had", %{conn: conn} do
      view = open_new(conn)

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

    test "a link with a data-target attribute opens in a new tab too", %{conn: conn} do
      view = open_new(conn)

      save(view, @attrs, ~s|<div><a href="https://a.org" data-target="menu">a</a></div>|)

      assert [%Announcement.Model{body: body}] = Repo.all(Announcement.Model)

      assert body ==
               ~s|<div><a href="https://a.org" data-target="menu" target="_blank">a</a></div>|
    end

    test "Cancel goes back to the list without saving", %{conn: conn} do
      view = open_new(conn)

      render_click(view, "cancel_announcement")

      assert_redirect(view, @list_path)
      assert announcement_count() == 0
    end

    test "the buttons stay active on empty fields, and a tap says what to fill in", %{
      conn: conn
    } do
      view = open_new(conn)

      refute has_element?(view, "[data-testid='save-announcement-button'][disabled]")
      refute has_element?(view, "[data-testid='publish-announcement-button'][disabled]")

      html = save(view, %{"kind" => "release_notes", "priority" => "normal"}, "")

      assert announcement_count() == 0
      assert has_element?(view, "[data-testid='announcement-form']")
      assert html =~ "Please fill out this field"
      refute has_element?(view, "[data-testid='save-announcement-button'][disabled]")
      refute has_element?(view, "[data-testid='publish-announcement-button'][disabled]")

      html = publish(view, %{"kind" => "release_notes", "priority" => "normal"}, "")

      assert announcement_count() == 0
      assert html =~ "Please fill out this field"
    end

    test "a body without text is refused", %{conn: conn} do
      view = open_new(conn)

      html = save(view, @attrs, ~s(<div><figure><img src="https://eyra.co/a.png"></figure></div>))

      assert announcement_count() == 0
      assert has_element?(view, "[data-testid='announcement-form']")
      assert html =~ "Please fill out this field"
    end

    test "a title over 255 characters is refused", %{conn: conn} do
      view = open_new(conn)

      html = save(view, %{@attrs | "title" => String.duplicate("a", 256)}, "<div>Text</div>")

      assert announcement_count() == 0
      assert html =~ "should be at most 255 character(s)"
    end

    test "events do nothing once the flag is off", %{conn: conn} do
      view = open_new(conn)
      set_feature_flag(:announcements, false)

      save(view, @attrs, "<div>Text</div>")

      assert announcement_count() == 0
      assert has_element?(view, "[data-testid='announcement-form']")
    end
  end

  describe "an existing announcement" do
    # Two creators: the audience `published!/1` publishes to.
    setup do
      %{creators: [Factories.insert!(:creator), Factories.insert!(:creator)]}
    end

    test "opens the same page with its fields", %{conn: conn, admin: admin} do
      draft = draft!(admin)
      view = open_existing(conn, draft)

      assert has_element?(view, "[data-testid='announcement-compose-page']", "Edit announcement")
      html = view |> element("[data-testid='announcement-form']") |> render()
      assert html =~ ~s(value="March release")
      assert html =~ ~s(value="What changed")
      assert has_element?(view, "[data-testid='announcement-audience']")
    end

    test "a saved announcement is opened again and published", %{conn: conn, admin: admin} do
      %{id: id} = draft = draft!(admin)
      view = open_existing(conn, draft)

      publish(view, %{@attrs | "title" => "April release"}, "<div>Text</div>")

      assert_redirect(view, @list_path)

      assert [%Announcement.Model{id: ^id, title: "April release", published_at: %DateTime{}}] =
               Repo.all(Announcement.Model)
    end

    test "a published announcement opens with only its title, summary and body", %{
      conn: conn,
      admin: admin
    } do
      view = open_existing(conn, published!(admin))

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
      %{id: id, published_at: published_at} = published = published!(admin)
      enqueued = all_enqueued()

      view = open_existing(conn, published)

      save(
        view,
        %{"title" => "Published, corrected", "summary" => "Summary, corrected"},
        ~s|<div>See <a href="https://eyra.co/v2">the notes</a></div>|
      )

      assert_redirect(view, @list_path)

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
    end

    test "a second page doesn't undo a correction saved in a first page", %{
      conn: conn,
      admin: admin
    } do
      published = published!(admin)
      first = open_existing(conn, published)
      second = open_existing(conn, published)

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
      view = open_existing(conn, published!(admin))

      save(view, %{"title" => "Changed", "priority" => "high"}, "<div>Text</div>")

      assert [%Announcement.Model{title: "Published", priority: :normal}] =
               Repo.all(Announcement.Model)

      assert has_element?(view, "[data-testid='announcement-form']")
    end

    test "a page opened before the announcement was published doesn't change it on Save", %{
      conn: conn,
      admin: admin
    } do
      draft = draft!(admin)
      view = open_existing(conn, draft)
      {:ok, _} = Announcement.Public.publish_announcement(draft, [], nil, 2)

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
             ] = Repo.all(Announcement.Model)

      assert has_element?(view, "[data-testid='announcement-form']")

      assert has_element?(
               view,
               "[data-testid='announcement-compose-notice']",
               "This announcement was published in the meantime, so your changes were not saved."
             )
    end

    test "a page opened before the announcement was published doesn't change it on Publish", %{
      conn: conn,
      admin: admin
    } do
      draft = draft!(admin)
      view = open_existing(conn, draft)
      toggle_filter(view, "verified")
      {:ok, _} = Announcement.Public.publish_announcement(draft, [], nil, 2)

      publish(view, %{@attrs | "title" => "Changed after publish"}, "<div>X</div>")

      assert [%Announcement.Model{title: "March release"}] = Repo.all(Announcement.Model)
      assert [_] = all_enqueued(worker: Announcement.DeliverJob)

      assert has_element?(
               view,
               "[data-testid='announcement-compose-notice']",
               "published in the meantime"
             )
    end
  end

  describe "publishing" do
    setup do
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      %{
        verified: Factories.insert!(:creator, %{email: "anna@example.org", verified_at: now}),
        unverified: Factories.insert!(:creator, %{email: "bram@example.org"}),
        deactivated:
          Factories.insert!(:creator, %{email: "carla@example.org", confirmed_at: nil}),
        member: Factories.insert!(:member, %{email: "dirk@example.org"})
      }
    end

    test "the form shows the audience, the count and whether email is sent", %{conn: conn} do
      view = open_new(conn)

      assert has_element?(view, "[data-testid='announcement-audience']", "Creators")
      assert recipient_count_text(view) =~ "2 creators will receive this announcement."
      assert has_element?(view, "[data-testid='announcement-email-notice']", "No email is sent.")
    end

    test "choosing high priority says an email is sent", %{conn: conn} do
      view = open_new(conn)

      render_change(view, "change_announcement", %{"announcement" => %{"priority" => "high"}})

      assert has_element?(
               view,
               "[data-testid='announcement-email-notice']",
               "Each recipient also gets an email."
             )
    end

    test "Verified narrows the count", %{conn: conn} do
      view = open_new(conn)

      toggle_filter(view, "verified")

      assert recipient_count_text(view) =~ "1 creator will receive this announcement."
    end

    test "a chosen filter is shown as chosen", %{conn: conn} do
      view = open_new(conn)

      toggle_filter(view, "verified")

      assert has_element?(view, "[data-testid='audience-filter-verified'] .bg-primary")
      refute has_element?(view, "[data-testid='audience-filter-unverified'] .bg-primary")
    end

    test "choosing a filter again drops it", %{conn: conn} do
      view = open_new(conn)

      toggle_filter(view, "verified")
      toggle_filter(view, "verified")

      assert recipient_count_text(view) =~ "2 creators will receive this announcement."
    end

    test "the participant filters can't be chosen", %{conn: conn} do
      view = open_new(conn)

      refute has_element?(view, "[data-testid='audience-filter-affiliate']")
      toggle_filter(view, "affiliate")

      assert recipient_count_text(view) =~ "2 creators will receive this announcement."
    end

    test "search narrows the count", %{conn: conn} do
      view = open_new(conn)

      search(view, "bram")

      assert recipient_count_text(view) =~ "1 creator will receive this announcement."
    end

    test "publishes to the chosen audience and goes back to the list", %{
      conn: conn,
      unverified: unverified
    } do
      view = open_new(conn)
      toggle_filter(view, "unverified")

      publish(view, @attrs, "<div>Text</div>")

      assert_redirect(view, @list_path)

      assert [%Announcement.Model{id: id, published_at: %DateTime{}}] =
               Repo.all(Announcement.Model)

      assert stored_recipient_ids() == [[unverified.id]]
      assert_enqueued(worker: Announcement.DeliverJob, args: %{"announcement_id" => id})
    end

    test "the browser can't choose the recipients", %{
      conn: conn,
      verified: verified,
      member: member
    } do
      view = open_new(conn)
      toggle_filter(view, "verified")

      publish(
        view,
        Map.merge(@attrs, %{"recipient_ids" => [member.id], "published_at" => "2020-01-01"}),
        "<div>Text</div>"
      )

      assert stored_recipient_ids() == [[verified.id]]
    end

    test "with nobody in the audience, Publish says what to change and publishes nothing", %{
      conn: conn
    } do
      view = open_new(conn)
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

    test "changing the audience after a refused Publish drops the notice", %{conn: conn} do
      view = open_new(conn)
      search(view, "nobody")
      publish(view, @attrs, "<div>Text</div>")
      assert has_element?(view, "[data-testid='announcement-compose-notice']")

      search(view, "bram")

      refute has_element?(view, "[data-testid='announcement-compose-notice']")
      assert recipient_count_text(view) =~ "1 creator will receive this announcement."
    end

    test "when the audience emptied since it was shown, nothing is published", %{
      conn: conn,
      unverified: unverified
    } do
      view = open_new(conn)
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

    test "Publish sends the count the admin sees", %{conn: conn} do
      view = open_new(conn)

      assert has_element?(view, "button[data-testid='publish-announcement-button'][value='2']")
      toggle_filter(view, "verified")
      assert has_element?(view, "button[data-testid='publish-announcement-button'][value='1']")
    end

    test "when the audience changed since it was shown, nothing is published", %{conn: conn} do
      view = open_new(conn)
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

    test "after the audience changed, Publish again publishes to the new count", %{conn: conn} do
      view = open_new(conn)
      Factories.insert!(:creator, %{email: "eva@example.org"})
      publish(view, @attrs, "<div>Text</div>", "2")

      publish(view, @attrs, "<div>Text</div>")

      assert_redirect(view, @list_path)
      assert [%Announcement.Model{published_at: %DateTime{}}] = Repo.all(Announcement.Model)
      assert [ids] = stored_recipient_ids()
      assert length(ids) == 3
    end
  end

  describe "access" do
    test "is not found while the flag is off", %{conn: conn, admin: admin} do
      %{id: id} = draft!(admin)
      set_feature_flag(:announcements, false)

      assert_error_sent(404, fn -> get(conn, ~p"/admin/announcement/new") end)
      assert_error_sent(404, fn -> get(conn, ~p"/admin/announcement/#{id}") end)
    end

    test "is not found for an announcement that doesn't exist", %{conn: conn} do
      assert_error_sent(404, fn -> get(conn, "/admin/announcement/0") end)
      assert_error_sent(404, fn -> get(conn, "/admin/announcement/latest") end)
    end

    for role <- [:creator, :member] do
      test "is refused to a #{role}", %{admin: admin} do
        %{id: id} = draft!(admin)
        conn = sign_in(Factories.insert!(unquote(role)))

        for path <- [~p"/admin/announcement/new", ~p"/admin/announcement/#{id}"] do
          assert {:error, {:redirect, %{to: "/access_denied"}}} = live(conn, path)
        end
      end
    end

    test "is refused to an org admin", %{admin: admin} do
      %{id: id} = draft!(admin)
      user = Factories.insert!(:member)
      make_org_admin(user)
      conn = sign_in(user)

      assert_error_sent(403, fn -> get(conn, ~p"/admin/announcement/new") end)
      assert_error_sent(403, fn -> get(conn, ~p"/admin/announcement/#{id}") end)
    end

    test "asks a signed-out visitor to sign in", %{admin: admin} do
      %{id: id} = draft!(admin)

      conn = get(MicaWeb.ConnCase.build_conn(), ~p"/admin/announcement/#{id}")

      assert redirected_to(conn) == Mica.SaaS.module().sign_in_page()
    end
  end
end
