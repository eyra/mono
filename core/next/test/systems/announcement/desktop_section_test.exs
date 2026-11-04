defmodule Next.Systems.Announcement.DesktopSectionTest do
  use MicaWeb.ConnCase, async: false
  use Mica.FeatureFlags.Test

  import Phoenix.LiveViewTest

  alias Mica.Repo
  alias Next.Systems.Announcement
  alias Next.Systems.Announcement.NextActions.ReadAnnouncement
  alias Systems.NextAction
  alias Systems.Project

  @section "#desktop_section_announcements"
  @items "#{@section} [data-testid=announcement-item]"

  setup ctx do
    set_feature_flag(:announcements, true)

    author = Factories.insert!(:admin)
    creator = Factories.insert!(:creator)
    {:ok, ctx} = login(creator, ctx)

    Keyword.merge(ctx, author: author, creator: creator)
  end

  test "lists the six newest announcements, newest first", %{conn: conn} = ctx do
    announcements =
      for day <- 1..7 do
        announcement = create_announcement!(ctx.author, "Announcement #{day}", day)
        insert_recipient!(announcement, ctx.creator)
        announcement
      end

    {:ok, view, _html} = live(conn, ~p"/desktop")

    assert has_element?(view, @section, "Announcements")

    expected_ids =
      announcements
      |> Enum.reverse()
      |> Enum.take(6)
      |> Enum.map(&"announcement_item_#{&1.id}")

    assert item_ids(view) == expected_ids
    refute has_element?(view, @section, "Announcement 1")
  end

  test "shows title, summary and publication date, and links to the announcement page",
       %{conn: conn} = ctx do
    %{id: id} = announcement = create_announcement!(ctx.author, "Release notes October", 28)
    insert_recipient!(announcement, ctx.creator)

    {:ok, view, _html} = live(conn, ~p"/desktop")

    item = view |> element("#announcement_item_#{id}") |> render()
    assert item =~ "Release notes October"
    assert item =~ "What changed this month"
    assert item =~ "28 October 2026"
    assert item =~ ~s|href="/announcement/#{id}"|
  end

  test "marks unread announcements", %{conn: conn} = ctx do
    read = create_announcement!(ctx.author, "Read one", 1)
    unread = create_announcement!(ctx.author, "Unread one", 2)
    insert_recipient!(read, ctx.creator, ~U[2026-10-03 10:00:00Z])
    insert_recipient!(unread, ctx.creator)

    {:ok, view, _html} = live(conn, ~p"/desktop")

    assert has_element?(view, "#announcement_item_#{unread.id}[data-unread=true]", "Unread")
    assert has_element?(view, "#announcement_item_#{read.id}[data-unread=false]")
    refute has_element?(view, "#announcement_item_#{read.id}", "Unread")
  end

  test "leaves out announcements the user did not receive or that are not published",
       %{conn: conn} = ctx do
    other = Factories.insert!(:creator)
    insert_recipient!(create_announcement!(ctx.author, "For someone else", 1), other)
    insert_recipient!(create_announcement!(ctx.author, "Draft", nil), ctx.creator)
    insert_recipient!(create_announcement!(ctx.author, "Received", 2), ctx.creator)

    {:ok, view, _html} = live(conn, ~p"/desktop")

    assert has_element?(view, @items, "Received")
    refute has_element?(view, @section, "For someone else")
    refute has_element?(view, @section, "Draft")
  end

  test "is hidden for a user without announcements", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/desktop")

    assert html =~ "Recent items"
    refute has_element?(view, @section)
  end

  test "is hidden while the feature flag is off, and Desktop is unchanged", %{conn: conn} = ctx do
    set_feature_flag(:announcements, false)
    insert_recipient!(create_announcement!(ctx.author, "Release notes", 1), ctx.creator)

    {:ok, view, html} = live(conn, ~p"/desktop")

    assert html =~ "Recent items"
    refute has_element?(view, @section)
    refute html =~ "Release notes"
  end

  test "shows above Recent items, which keeps showing only project items",
       %{conn: conn} = ctx do
    {:ok, %{project: project}} = Project.Assembly.create("Project", ctx.creator, :empty)
    {:ok, _} = Project.Assembly.create_item(:questionnaire, "Study", project.root, ctx.creator)
    insert_recipient!(create_announcement!(ctx.author, "Release notes", 1), ctx.creator)

    {:ok, view, html} = live(conn, ~p"/desktop")

    {section, _} = :binary.match(html, "desktop_section_announcements")
    {recent_items, _} = :binary.match(html, "Recent items")
    assert section < recent_items

    recent = html |> binary_part(recent_items, byte_size(html) - recent_items)
    assert recent =~ ~r/Recent items\s*<span class="text-primary"> 1<\/span>/
    assert recent =~ "Study"
    refute recent =~ "Release notes"
    assert has_element?(view, @items, "Release notes")
  end

  test "shows each announcement as a card", %{conn: conn} = ctx do
    %{id: id} = announcement = create_announcement!(ctx.author, "Release notes", 1)
    insert_recipient!(announcement, ctx.creator)

    {:ok, view, _html} = live(conn, ~p"/desktop")

    assert has_element?(
             view,
             "#{@section} .grid #announcement_item_#{id} .rounded-lg",
             "Release notes"
           )
  end

  describe "live" do
    test "an opened announcement turns read", %{conn: conn} = ctx do
      %{id: id} = announcement = create_announcement!(ctx.author, "Release notes", 1)
      insert_recipient!(announcement, ctx.creator)
      create_to_do!(ctx.creator, id)

      {:ok, desktop, _html} = live(conn, ~p"/desktop")
      assert has_element?(desktop, "#announcement_item_#{id}[data-unread=true]")

      {:ok, _page, _html} = live(conn, ~p"/announcement/#{id}")

      assert has_element?(desktop, "#announcement_item_#{id}[data-unread=false]")
      assert NextAction.Public.count_next_actions(ctx.creator) == 0
    end

    test "an edited title and summary show at once", %{conn: conn} = ctx do
      %{id: id} = announcement = create_announcement!(ctx.author, "Release notes", 1)
      insert_recipient!(announcement, ctx.creator)
      create_to_do!(ctx.creator, id)

      {:ok, desktop, _html} = live(conn, ~p"/desktop")
      assert has_element?(desktop, "#announcement_item_#{id}", "Release notes")

      {:ok, _} =
        Announcement.Public.update_announcement(announcement, %{
          title: "Release notes, corrected",
          summary: "What really changed"
        })

      item = desktop |> element("#announcement_item_#{id}") |> render()
      assert item =~ "Release notes, corrected"
      assert item =~ "What really changed"
      # The section and the To-do both show the new summary.
      html = render(desktop)
      assert length(String.split(html, "What really changed")) == 3
      refute html =~ "What changed this month"
      assert has_element?(desktop, "#announcement_item_#{id}[data-unread=true]")
    end
  end

  defp item_ids(view) do
    view
    |> render()
    |> Floki.parse_document!()
    |> Floki.find(@items)
    |> Enum.flat_map(&Floki.attribute(&1, "id"))
  end

  defp create_announcement!(author, title, october_day) do
    {:ok, announcement} =
      Announcement.Public.create_announcement(author, %{
        kind: :release_notes,
        title: title,
        summary: "What changed this month",
        body: "<div>New features</div>"
      })

    announcement
    |> Ecto.Changeset.change(published_at: published_at(october_day))
    |> Repo.update!()
  end

  defp published_at(nil), do: nil
  defp published_at(day), do: DateTime.new!(Date.new!(2026, 10, day), ~T[09:00:00])

  defp insert_recipient!(%{id: announcement_id}, %{id: user_id}, read_at \\ nil) do
    %Announcement.RecipientModel{
      announcement_id: announcement_id,
      user_id: user_id,
      read_at: read_at
    }
    |> Announcement.RecipientModel.changeset(%{})
    |> Repo.insert!()
  end

  defp create_to_do!(user, announcement_id) do
    NextAction.Public.create_next_action(user, ReadAnnouncement,
      key: ReadAnnouncement.key(announcement_id),
      params: ReadAnnouncement.params(announcement_id)
    )
  end
end
