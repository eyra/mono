defmodule Next.Systems.Announcement.ListPageTest do
  use MicaWeb.ConnCase, async: false
  use Mica.FeatureFlags.Test

  import Phoenix.LiveViewTest

  alias Mica.Repo
  alias Next.Systems.Announcement
  alias Next.Systems.Announcement.NextActions.ReadAnnouncement
  alias Systems.NextAction

  setup ctx do
    set_feature_flag(:announcements, true)
    author = Factories.insert!(:admin)
    user = Factories.insert!(:creator)
    {:ok, ctx} = login(user, ctx)
    Keyword.merge(ctx, author: author, user: user)
  end

  test "all received announcements remain reachable beyond the Desktop preview", ctx do
    announcements = for day <- 1..8, do: received!(ctx, "Announcement #{day}", day)
    {:ok, desktop, _} = live(ctx.conn, ~p"/desktop")
    refute has_element?(desktop, "#announcement_item_#{hd(announcements).id}")

    desktop
    |> element("#desktop_section_announcements [data-testid=section-full-list]")
    |> render_click()

    assert_redirect(desktop, "/announcements")
    {:ok, list, _} = live(ctx.conn, ~p"/announcements")

    ids =
      list
      |> render()
      |> Floki.parse_document!()
      |> Floki.find("[data-testid=announcement-item]")
      |> Floki.attribute("id")

    assert ids == Enum.map(Enum.reverse(announcements), &"announcement_item_#{&1.id}")
  end

  test "the list shows read and unread items and does not mark either read", ctx do
    announcement = received!(ctx, "Unread", 1)
    other = received!(ctx, "Read", 2)
    recipient = Announcement.Public.get_received(ctx.user, other.id)
    Announcement.Public.mark_read(recipient)

    NextAction.Public.create_next_action(ctx.user, ReadAnnouncement,
      key: ReadAnnouncement.key(announcement.id),
      params: ReadAnnouncement.params(announcement.id)
    )

    {:ok, view, _} = live(ctx.conn, ~p"/announcements")
    assert has_element?(view, "#announcement_item_#{announcement.id}[data-unread=true]", "Unread")
    assert has_element?(view, "#announcement_item_#{other.id}[data-unread=false]", "Read")
    assert Announcement.Public.get_received(ctx.user, announcement.id).read_at == nil
    assert NextAction.Public.count_next_actions(ctx.user) == 1

    view |> element("#announcement_item_#{announcement.id}") |> render_click()
    assert_redirect(view, Announcement.Private.page_path(announcement.id))
    {:ok, _page, _} = live(ctx.conn, Announcement.Private.page_path(announcement.id))
    assert %DateTime{} = Announcement.Public.get_received(ctx.user, announcement.id).read_at
    assert NextAction.Public.count_next_actions(ctx.user) == 0
  end

  test "other users' announcements and drafts are absent, even with a user_id parameter", ctx do
    received!(ctx, "Mine", 1)
    other_user = Factories.insert!(:creator)
    received!(%{ctx | user: other_user}, "Other user's secret", 2)
    received!(ctx, "Draft", nil)
    {:ok, view, _} = live(ctx.conn, "/announcements?user_id=#{other_user.id}")
    assert has_element?(view, "[data-testid=announcement-item]", "Mine")
    refute render(view) =~ "Other user's secret"
    refute render(view) =~ "Draft"
  end

  test "an empty list has a useful empty state", ctx do
    {:ok, view, _} = live(ctx.conn, ~p"/announcements")
    assert render(view) =~ "You have no announcements yet."
    refute has_element?(view, "[data-testid=announcement-item]")
  end

  test "an edited announcement refreshes the list without marking it read", ctx do
    announcement = received!(ctx, "Before", 1)
    {:ok, view, _} = live(ctx.conn, ~p"/announcements")
    {:ok, _} = Announcement.Public.update_announcement(announcement, %{title: "After"})
    assert has_element?(view, "#announcement_item_#{announcement.id}[data-unread=true]", "After")
  end

  test "reading an announcement elsewhere refreshes its unread marker", ctx do
    announcement = received!(ctx, "News", 1)
    {:ok, view, _} = live(ctx.conn, ~p"/announcements")
    {:ok, _, _} = live(ctx.conn, Announcement.Private.page_path(announcement.id))
    assert has_element?(view, "#announcement_item_#{announcement.id}[data-unread=false]")
  end

  test "the feature flag protects the list", ctx do
    set_feature_flag(:announcements, false)
    assert_raise Ecto.NoResultsError, fn -> live(ctx.conn, ~p"/announcements") end
  end

  test "signed-out visitors must sign in", _ctx do
    assert {:error, {:redirect, %{to: to}}} =
             live(MicaWeb.ConnCase.build_conn(), ~p"/announcements")

    assert to =~ "/user/"
  end

  defp received!(ctx, title, day) do
    {:ok, announcement} =
      Announcement.Public.create_announcement(ctx.author, %{
        kind: :release_notes,
        title: title,
        summary: "Summary",
        body: "<div>Body</div>"
      })

    published_at = if day, do: DateTime.new!(Date.new!(2026, 10, day), ~T[09:00:00])

    announcement =
      announcement |> Ecto.Changeset.change(published_at: published_at) |> Repo.update!()

    %Announcement.RecipientModel{announcement_id: announcement.id, user_id: ctx.user.id}
    |> Announcement.RecipientModel.changeset(%{})
    |> Repo.insert!()

    announcement
  end
end
