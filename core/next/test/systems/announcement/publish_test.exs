defmodule Systems.Announcement.PublishTest do
  use Core.DataCase, async: true
  use Oban.Testing, repo: Core.Repo
  use Bamboo.Test

  import Ecto.Query

  alias Core.Repo
  alias Systems.Account
  alias Systems.Announcement
  alias Systems.Announcement.NextActions.ReadAnnouncement
  alias Systems.Assignment.NextActions.PendingContributions
  alias Systems.NextAction

  @now NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

  setup do
    author = Factories.insert!(:admin)

    verified =
      creator!("anna.verified@example.org", "Anna de Vries", verified_at: @now)

    unverified = creator!("bram.unverified@example.org", "Bram Jansen")
    deactivated = creator!("carla.gone@example.org", "Carla Gone", confirmed_at: nil)

    member =
      Factories.insert!(:member, %{
        email: "dirk.member@example.org",
        profile: %Account.UserProfileModel{fullname: "Dirk Member"}
      })

    %{
      author: author,
      verified: verified,
      unverified: unverified,
      deactivated: deactivated,
      member: member
    }
  end

  defp creator!(email, fullname, attrs \\ []) do
    Factories.insert!(
      :creator,
      Map.merge(
        %{email: email, profile: %Account.UserProfileModel{fullname: fullname}},
        Map.new(attrs)
      )
    )
  end

  defp announcement!(author, attrs \\ %{}) do
    {:ok, announcement} =
      Announcement.Public.create_announcement(
        author,
        Map.merge(
          %{
            kind: :release_notes,
            title: "Release notes",
            summary: "What changed",
            body: "<div>New features</div>"
          },
          attrs
        )
      )

    announcement
  end

  # Publishes with the count the admin would have seen.
  defp publish(announcement, filters, query) do
    shown_count = length(Announcement.Public.list_audience_ids(filters, query))
    Announcement.Public.publish_announcement(announcement, filters, query, shown_count)
  end

  defp publish!(announcement, filters \\ [], query \\ nil) do
    {:ok, announcement} = publish(announcement, filters, query)
    assert :ok = perform_job(Announcement.DeliverJob, %{"announcement_id" => announcement.id})
    announcement
  end

  defp recipient_ids(%Announcement.Model{} = announcement) do
    announcement
    |> Announcement.Public.list_recipients()
    |> Enum.map(& &1.user_id)
    |> Enum.sort()
  end

  defp stored_recipient_ids(%Announcement.Model{id: id}) do
    Repo.one!(from(a in Announcement.Model, where: a.id == ^id, select: a.recipient_ids))
  end

  defp to_dos(%Account.User{id: user_id}) do
    from(na in NextAction.Model, where: na.user_id == ^user_id, order_by: na.key)
    |> Repo.all()
  end

  defp ids(users), do: users |> Enum.map(& &1.id) |> Enum.sort()

  describe "list_audience_ids/2" do
    test "has every creator with a confirmed account", ctx do
      assert Enum.sort(Announcement.Public.list_audience_ids([], nil)) ==
               ids([ctx.verified, ctx.unverified])
    end

    test "Verified and Unverified narrow it", %{verified: verified, unverified: unverified} do
      assert Announcement.Public.list_audience_ids([:verified], nil) == [verified.id]
      assert Announcement.Public.list_audience_ids([:unverified], nil) == [unverified.id]
    end

    test "filters combine with AND" do
      assert Announcement.Public.list_audience_ids([:verified, :unverified], nil) == []
    end

    test "search matches the email or the full name, every word", ctx do
      assert Announcement.Public.list_audience_ids([], ["ANNA"]) == [ctx.verified.id]
      assert Announcement.Public.list_audience_ids([], ["jansen"]) == [ctx.unverified.id]

      assert Announcement.Public.list_audience_ids([], ["bram", "verified"]) == [
               ctx.unverified.id
             ]

      assert Announcement.Public.list_audience_ids([:verified], ["bram"]) == []
    end

    test "search never reaches deactivated accounts or non-creators" do
      assert Announcement.Public.list_audience_ids([], ["carla"]) == []
      assert Announcement.Public.list_audience_ids([], ["dirk"]) == []
    end

    test "ignores the participant filters", ctx do
      assert Enum.sort(Announcement.Public.list_audience_ids([:affiliate, :in_pool], nil)) ==
               ids([ctx.verified, ctx.unverified])
    end
  end

  describe "publish_announcement/3" do
    test "fixes the audience and queues the delivery", %{author: author, verified: verified} do
      announcement = announcement!(author)

      assert {:ok, %Announcement.Model{published_at: %DateTime{}, recipient_ids: recipient_ids}} =
               publish(announcement, [:verified], nil)

      assert recipient_ids == [verified.id]

      assert_enqueued(
        worker: Announcement.DeliverJob,
        args: %{"announcement_id" => announcement.id}
      )

      assert %{published_at: %DateTime{}} = Announcement.Public.get_announcement!(announcement.id)
      assert stored_recipient_ids(announcement) == [verified.id]
    end

    test "an empty audience leaves it unpublished", %{author: author} do
      announcement = announcement!(author)

      assert {:error, :no_recipients} =
               publish(announcement, [], ["nobody"])

      assert %{published_at: nil} = Announcement.Public.get_announcement!(announcement.id)
      assert stored_recipient_ids(announcement) == []

      refute_enqueued(worker: Announcement.DeliverJob)
    end

    test "publishes once", %{author: author} do
      announcement = announcement!(author)
      {:ok, published} = publish(announcement, [], nil)

      assert {:error, :already_published} =
               publish(published, [], nil)

      assert {:error, :already_published} =
               publish(announcement, [], nil)

      assert [_] = all_enqueued(worker: Announcement.DeliverJob)
    end
  end

  describe "publish_announcement/4 with the count the admin saw" do
    test "doesn't publish when the audience changed since", %{author: author} do
      announcement = announcement!(author)
      shown_count = length(Announcement.Public.list_audience_ids([], nil))
      creator!("eva.new@example.org", "Eva New")

      assert {:error, {:audience_changed, count}} =
               Announcement.Public.publish_announcement(announcement, [], nil, shown_count)

      assert count == shown_count + 1
      assert %{published_at: nil} = Announcement.Public.get_announcement!(announcement.id)
      refute_enqueued(worker: Announcement.DeliverJob)
    end

    test "publishes with the new count", %{author: author} do
      announcement = announcement!(author)
      creator!("eva.new@example.org", "Eva New")
      count = length(Announcement.Public.list_audience_ids([], nil))

      assert {:ok, %{recipient_ids: ids}} =
               Announcement.Public.publish_announcement(announcement, [], nil, count)

      assert length(ids) == count
    end
  end

  describe "update_announcement/2" do
    test "changes the title, summary and body of a published announcement", %{author: author} do
      published = publish!(announcement!(author))

      assert {:ok, %{title: "Release notes, corrected"}} =
               Announcement.Public.update_announcement(published, %{
                 title: "Release notes, corrected",
                 summary: "What really changed",
                 body: "<div>Fixed features</div>"
               })

      assert %{
               title: "Release notes, corrected",
               summary: "What really changed",
               body: "<div>Fixed features</div>",
               published_at: published_at
             } = Announcement.Public.get_announcement!(published.id)

      assert published_at == published.published_at
    end

    test "sends nothing again and keeps every read status", %{
      author: author,
      verified: verified,
      unverified: unverified
    } do
      published = publish!(announcement!(author))
      read = Announcement.Public.get_received(verified, published.id)
      %{read_at: read_at} = Announcement.Public.mark_read(read)
      enqueued = all_enqueued()

      assert {:ok, _} =
               Announcement.Public.update_announcement(published, %{title: "Corrected"})

      assert [%{read_at: ^read_at}] =
               Repo.all(from(r in Announcement.RecipientModel, where: r.user_id == ^verified.id))

      assert %{read_at: nil} = Announcement.Public.get_received(unverified, published.id)
      assert to_dos(verified) == []
      assert [%{key: key}] = to_dos(unverified)
      assert key == ReadAnnouncement.key(published.id)

      assert all_enqueued() == enqueued
      assert_no_emails_delivered()
    end

    test "refuses a new priority or kind once it is published", %{author: author} do
      published = publish!(announcement!(author))

      for attrs <- [%{priority: :high}, %{"priority" => "high", "title" => "Corrected"}] do
        assert {:error, :already_published} =
                 Announcement.Public.update_announcement(published, attrs)
      end

      assert %{title: "Release notes", priority: :normal} =
               Announcement.Public.get_announcement!(published.id)
    end

    test "accepts the priority and kind it already has", %{author: author} do
      published = publish!(announcement!(author))

      assert {:ok, %{title: "Corrected"}} =
               Announcement.Public.update_announcement(published, %{
                 "kind" => "release_notes",
                 "priority" => "normal",
                 "title" => "Corrected"
               })
    end

    test "refuses a second form on a copy that a first form has saved since", %{author: author} do
      loaded = publish!(announcement!(author))
      form = %{"title" => "Release notes", "summary" => "What changed"}

      assert {:ok, _} =
               Announcement.Public.update_announcement(
                 loaded,
                 Map.merge(form, %{"title" => "Release notes, corrected"})
               )

      assert {:error, :changed_since_loaded} =
               Announcement.Public.update_announcement(
                 loaded,
                 Map.merge(form, %{"body" => "<div>New features, link fixed</div>"})
               )

      assert %{title: "Release notes, corrected", body: "<div>New features</div>"} =
               Announcement.Public.get_announcement!(loaded.id)
    end

    test "refuses a second form on a draft that a first form has saved since", %{author: author} do
      loaded = announcement!(author)

      assert {:ok, saved} =
               Announcement.Public.update_announcement(loaded, %{title: "Release notes, v2"})

      assert {:error, :changed_since_loaded} =
               Announcement.Public.update_announcement(loaded, %{summary: "Other summary"})

      assert {:ok, _} = Announcement.Public.update_announcement(saved, %{summary: "Next summary"})

      assert %{title: "Release notes, v2", summary: "Next summary"} =
               Announcement.Public.get_announcement!(loaded.id)
    end

    test "never changes the audience", %{author: author, verified: verified, member: member} do
      published = publish!(announcement!(author), [:verified])

      {:ok, _} =
        Announcement.Public.update_announcement(published, %{
          recipient_ids: [member.id],
          published_at: nil
        })

      assert stored_recipient_ids(published) == [verified.id]
      assert %{published_at: %DateTime{}} = Announcement.Public.get_announcement!(published.id)
    end

    test "refuses a copy loaded before it was published", %{author: author} do
      announcement = announcement!(author)
      {:ok, _} = publish(announcement, [], nil)

      assert {:error, :already_published} =
               Announcement.Public.update_announcement(announcement, %{
                 title: "Changed",
                 priority: :high
               })

      assert %{title: "Release notes", priority: :normal} =
               Announcement.Public.get_announcement!(announcement.id)
    end
  end

  describe "reading announcements" do
    test "leaves the audience out", %{author: author} do
      %{id: id} = publish!(announcement!(author))

      assert %{recipient_ids: []} = Announcement.Public.get_announcement!(id)
      assert [%{recipient_ids: []}] = Announcement.Public.list_announcements()
    end

    test "count_audiences/1 counts each announcement's audience", %{author: author} do
      published = publish!(announcement!(author, %{title: "Published"}))
      draft = announcement!(author, %{title: "Draft"})

      assert Announcement.Public.count_audiences([published, draft]) == %{
               published.id => 2,
               draft.id => 0
             }
    end
  end

  describe "delivery" do
    test "gives each recipient a recipient row and one To-do", ctx do
      %{id: id} = announcement = publish!(announcement!(ctx.author))

      assert recipient_ids(announcement) == ids([ctx.verified, ctx.unverified])

      for user <- [ctx.verified, ctx.unverified] do
        assert [%NextAction.Model{action: action, key: key, params: params, count: 1}] =
                 to_dos(user)

        assert action == to_string(ReadAnnouncement)
        assert key == ReadAnnouncement.key(id)
        assert params == %{"announcement_id" => id}

        assert [%{title: "Release notes", description: "What changed", cta_action: cta_action}] =
                 NextAction.Public.list_next_actions(user)

        assert cta_action == %{type: :redirect, to: "/announcement/#{id}"}
      end

      for user <- [ctx.deactivated, ctx.member, ctx.author] do
        assert to_dos(user) == []
      end
    end

    test "the recipient count shown before publishing is the number of recipients", ctx do
      count = length(Announcement.Public.list_audience_ids([:unverified], nil))
      announcement = publish!(announcement!(ctx.author), [:unverified])

      assert length(recipient_ids(announcement)) == count
    end

    test "a high announcement's To-do has high priority", ctx do
      publish!(announcement!(ctx.author, %{priority: :high}), [:verified])

      assert [%NextAction.Model{priority: :high}] = to_dos(ctx.verified)
    end

    test "a normal announcement's To-do has low priority", ctx do
      publish!(announcement!(ctx.author, %{priority: :normal}), [:verified])

      assert [%NextAction.Model{priority: :low}] = to_dos(ctx.verified)
    end

    test "other To-dos keep their priority", ctx do
      NextAction.Public.create_next_action(ctx.verified, PendingContributions, key: "other")

      publish!(announcement!(ctx.author, %{priority: :high}), [:verified])
      publish!(announcement!(ctx.author, %{priority: :normal}), [:verified])

      assert %NextAction.Model{priority: :normal} =
               Repo.get_by!(NextAction.Model, user_id: ctx.verified.id, key: "other")
    end

    test "publishing to yourself reaches only your account", %{author: author} do
      admin = Repo.update!(Ecto.Changeset.change(author, creator: true))
      announcement = publish!(announcement!(admin), [], [admin.email])

      assert recipient_ids(announcement) == [admin.id]
      assert [_] = to_dos(admin)
    end

    test "publishing twice to the same audience gives two To-dos", ctx do
      first = publish!(announcement!(ctx.author, %{title: "First"}), [:verified])
      second = publish!(announcement!(ctx.author, %{title: "Second"}), [:verified])

      assert Enum.map(to_dos(ctx.verified), & &1.key) ==
               Enum.sort([ReadAnnouncement.key(first.id), ReadAnnouncement.key(second.id)])

      assert ctx.verified
             |> NextAction.Public.list_next_actions()
             |> Enum.map(& &1.title)
             |> Enum.sort() ==
               ["First", "Second"]
    end

    test "a creator who signs up later gets nothing", %{author: author} do
      {:ok, announcement} =
        publish(announcement!(author), [], nil)

      later = creator!("eva.later@example.org", "Eva Later")

      assert :ok = perform_job(Announcement.DeliverJob, %{"announcement_id" => announcement.id})

      refute later.id in recipient_ids(announcement)
      assert to_dos(later) == []
    end

    test "skips recipients whose account is gone", %{author: author, verified: verified} do
      {:ok, announcement} =
        publish(announcement!(author), [:verified], nil)

      gone_id = Repo.aggregate(Account.User, :max, :id) + 1

      from(a in Announcement.Model, where: a.id == ^announcement.id)
      |> Repo.update_all(set: [recipient_ids: [verified.id, gone_id]])

      assert :ok = perform_job(Announcement.DeliverJob, %{"announcement_id" => announcement.id})

      assert recipient_ids(announcement) == [verified.id]
    end

    test "running it again adds nothing", %{author: author, verified: verified} do
      announcement = publish!(announcement!(author))

      assert {:ok, 0} = Announcement.Public.deliver_announcement(announcement.id)

      assert [%NextAction.Model{count: 1}] = to_dos(verified)
      assert length(recipient_ids(announcement)) == 2
    end

    test "does nothing for an unpublished or unknown announcement", %{author: author} do
      announcement = announcement!(author)

      assert {:ok, 0} = Announcement.Public.deliver_announcement(announcement.id)
      assert {:ok, 0} = Announcement.Public.deliver_announcement(-1)
      assert recipient_ids(announcement) == []
    end

    test "reaches a large audience", %{author: author} do
      rows =
        for i <- 1..1_200 do
          %{
            email: "creator#{i}@example.org",
            displayname: "Creator",
            hashed_password: "not-used",
            creator: true,
            confirmed_at: @now,
            inserted_at: @now,
            updated_at: @now
          }
        end

      {1_200, _} = Repo.insert_all(Account.User, rows)
      announcement = publish!(announcement!(author))

      assert length(announcement.recipient_ids) == 1_202
      assert length(recipient_ids(announcement)) == 1_202

      action = to_string(ReadAnnouncement)
      key = ReadAnnouncement.key(announcement.id)

      assert 1_202 ==
               Repo.aggregate(
                 from(na in NextAction.Model, where: na.action == ^action and na.key == ^key),
                 :count
               )
    end
  end
end
