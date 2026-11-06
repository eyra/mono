defmodule Next.Systems.Announcement.ToDoOrderTest do
  use MicaWeb.ConnCase, async: false
  use Mica.FeatureFlags.Test
  use Oban.Testing, repo: Mica.Repo

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias Mica.Repo
  alias Next.Systems.Announcement
  alias Next.Systems.Announcement.NextActions.ReadAnnouncement
  alias Systems.Assignment.NextActions.PendingContributions
  alias Systems.NextAction

  @highlight "[data-testid=next-action-highlight]"
  @role_title "New contributions"

  setup ctx do
    set_feature_flag(:announcements, true)

    author = Factories.insert!(:admin)
    creator = Factories.insert!(:creator)
    align_assignment_and_announcement_ids!()
    assignment = Factories.insert!(:assignment)

    NextAction.Public.create_next_action(creator, PendingContributions,
      key: "#{assignment.id}",
      params: %{"assignment_id" => assignment.id}
    )

    {:ok, ctx} = login(creator, ctx)

    Keyword.merge(ctx, author: author, creator: creator)
  end

  describe "To-do page" do
    test "lists high announcements, then other To-dos, then normal announcements, newest first",
         %{conn: conn} = ctx do
      publish!(ctx, "Normal older", :normal, ~N[2026-10-01 10:00:00])
      publish!(ctx, "High older", :high, ~N[2026-10-02 10:00:00])
      publish!(ctx, "Normal newer", :normal, ~N[2026-10-03 10:00:00])
      publish!(ctx, "High newer", :high, ~N[2026-10-04 10:00:00])

      {:ok, _view, html} = live(conn, ~p"/todo")

      assert titles_in_order(html, [
               "High newer",
               "High older",
               @role_title,
               "Normal newer",
               "Normal older"
             ])
    end
  end

  for {page, path} <- [{"Projects", "/project"}, {"Desktop", "/desktop"}] do
    describe "#{page} highlight" do
      test "is an unread high announcement before another To-do", %{conn: conn} = ctx do
        publish!(ctx, "Normal announcement", :normal, ~N[2026-10-03 10:00:00])
        publish!(ctx, "High announcement", :high, ~N[2026-10-01 10:00:00])

        {:ok, view, _html} = live(conn, unquote(path))

        assert has_element?(view, @highlight, "High announcement")
      end

      test "is another To-do before a normal announcement", %{conn: conn} = ctx do
        publish!(ctx, "Normal announcement", :normal, ~N[2099-01-01 10:00:00])

        {:ok, view, _html} = live(conn, unquote(path))

        assert has_element?(view, @highlight, @role_title)
        refute has_element?(view, @highlight, "Normal announcement")
      end

      test "is the other To-do again once the high announcement is read", %{conn: conn} = ctx do
        high = publish!(ctx, "High announcement", :high, ~N[2026-10-01 10:00:00])
        Announcement.Public.mark_read(recipient(high, ctx.creator))

        {:ok, view, _html} = live(conn, unquote(path))

        assert has_element?(view, @highlight, @role_title)
      end
    end
  end

  # Publishes an announcement to the creator and dates its To-do at
  # `inserted_at`, so the order within a priority does not depend on timing.
  defp publish!(ctx, title, priority, inserted_at) do
    {:ok, announcement} =
      Announcement.Public.create_announcement(ctx.author, %{
        kind: :release_notes,
        title: title,
        summary: "Summary of #{title}",
        body: "<div>Body</div>",
        priority: priority
      })

    query = [ctx.creator.email]
    shown_count = length(Announcement.Public.list_audience_ids([], query))

    {:ok, announcement} =
      Announcement.Public.publish_announcement(announcement, [], query, shown_count)

    assert :ok = perform_job(Announcement.DeliverJob, %{"announcement_id" => announcement.id})

    action = to_string(ReadAnnouncement)
    key = ReadAnnouncement.key(announcement.id)

    {1, _} =
      from(na in NextAction.Model,
        where: na.user_id == ^ctx.creator.id and na.action == ^action and na.key == ^key
      )
      |> Repo.update_all(set: [inserted_at: inserted_at])

    announcement
  end

  # Gives the next assignment and the next announcement the same id, so the
  # first announcement's To-do has the same key as the assignment's To-do.
  defp align_assignment_and_announcement_ids! do
    Repo.query!("""
    SELECT setval('assignments_id_seq', id, false), setval('announcement_id_seq', id, false)
    FROM (SELECT GREATEST(nextval('assignments_id_seq'), nextval('announcement_id_seq')) AS id) next
    """)
  end

  defp recipient(%Announcement.Model{id: id}, %{id: user_id}) do
    Repo.get_by!(Announcement.RecipientModel, announcement_id: id, user_id: user_id)
  end

  defp titles_in_order(html, titles) do
    positions =
      Enum.map(titles, fn title ->
        assert {position, _} = :binary.match(html, title)
        position
      end)

    positions == Enum.sort(positions)
  end
end
