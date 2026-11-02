defmodule Systems.Announcement.EmailTest do
  use Core.DataCase, async: true
  use Oban.Testing, repo: Core.Repo

  import Ecto.Query

  alias Core.Repo
  alias Systems.Account
  alias Systems.Announcement
  alias Systems.Email
  alias Systems.NextAction

  @now NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

  @body """
  <div>New: <strong>exports</strong> &amp; filters.<br>Read the guide.</div>\
  <ul><li>Faster</li><li>Simpler</li></ul>\
  <div><a href="https://example.org/guide">The guide</a></div>\
  """

  setup do
    author = Factories.insert!(:admin)
    anna = creator!("anna@example.org")
    bram = creator!("bram@example.org")

    %{author: author, anna: anna, bram: bram}
  end

  defp creator!(email) do
    Factories.insert!(:creator, %{email: email, confirmed_at: @now})
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
            body: @body,
            priority: :high
          },
          attrs
        )
      )

    announcement
  end

  defp publish!(announcement, query \\ nil) do
    shown_count = length(Announcement.Public.list_audience_ids([], query))

    {:ok, announcement} =
      Announcement.Public.publish_announcement(announcement, [], query, shown_count)

    assert :ok = perform_job(Announcement.DeliverJob, %{"announcement_id" => announcement.id})
    announcement
  end

  defp dispatcher_jobs, do: all_enqueued(worker: Email.Dispatcher)

  defp queued_addresses do
    dispatcher_jobs()
    |> Enum.flat_map(fn %{args: %{"to" => to}} -> to end)
    |> Enum.sort()
  end

  # Runs the email pipeline: each dispatcher job, then each delivery job.
  defp send_emails do
    for %{args: args} <- dispatcher_jobs() do
      assert :ok = perform_job(Email.Dispatcher, args)
    end

    for %{args: args} <- all_enqueued(worker: Email.Delivery) do
      assert :ok = perform_job(Email.Delivery, args)
    end

    delivered_emails([])
  end

  defp delivered_emails(emails) do
    receive do
      {:delivered_email, email} -> delivered_emails([email | emails])
    after
      0 -> Enum.sort_by(emails, & &1.to)
    end
  end

  describe "publishing a high-priority announcement" do
    test "queues one email per recipient", %{author: author} do
      publish!(announcement!(author))

      assert queued_addresses() == ["anna@example.org", "bram@example.org"]
    end

    test "sends the title, the summary, the full body and a link", %{author: author} do
      %{id: id} = publish!(announcement!(author))
      url = CoreWeb.Endpoint.url() <> "/announcement/#{id}"

      assert [
               %{to: [nil: "anna@example.org"], subject: "Release notes"},
               %{to: [nil: "bram@example.org"], subject: "Release notes", html_body: html} =
                 email
             ] = send_emails()

      text = email.text_body

      assert html =~ "Release notes"
      assert html =~ "What changed"
      assert html =~ "<strong>exports</strong> &amp; filters."
      assert html =~ "<li>Simpler</li>"
      assert html =~ ~s(<a href="#{url}">Read this announcement in Next</a>)

      assert text =~ "Release notes\n\nWhat changed"
      assert text =~ "New: exports & filters.\nRead the guide.\n\n- Faster\n- Simpler"
      assert text =~ "The guide (https://example.org/guide)"
      assert text =~ "Read this announcement in Next:\n#{url}"
      refute text =~ "<"
    end

    test "running the delivery again queues no second email", %{author: author} do
      announcement = publish!(announcement!(author))

      assert :ok = perform_job(Announcement.DeliverJob, %{"announcement_id" => announcement.id})
      assert {:ok, 0} = Announcement.Public.deliver_announcement(announcement.id)

      assert [_] = dispatcher_jobs()
      assert queued_addresses() == ["anna@example.org", "bram@example.org"]
    end

    test "a recipient added on a later run gets only their own email", ctx do
      {:ok, announcement} =
        Announcement.Public.publish_announcement(announcement!(ctx.author), [], nil, 2)

      # A first run that reached only Anna, as if it stopped before Bram.
      from(a in Announcement.Model, where: a.id == ^announcement.id)
      |> Repo.update_all(set: [recipient_ids: [ctx.anna.id]])

      assert :ok = perform_job(Announcement.DeliverJob, %{"announcement_id" => announcement.id})

      from(a in Announcement.Model, where: a.id == ^announcement.id)
      |> Repo.update_all(set: [recipient_ids: [ctx.anna.id, ctx.bram.id]])

      assert :ok = perform_job(Announcement.DeliverJob, %{"announcement_id" => announcement.id})

      assert [["anna@example.org"], ["bram@example.org"]] =
               dispatcher_jobs() |> Enum.map(& &1.args["to"]) |> Enum.sort()
    end

    test "reaches a large audience in batches, once each", %{author: author} do
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
      publish!(announcement!(author))

      assert length(dispatcher_jobs()) == 3

      addresses = queued_addresses()
      assert length(addresses) == 1_202
      assert addresses == Enum.uniq(addresses)
    end

    test "publishing to yourself emails only you", %{author: author} do
      admin = Repo.update!(Ecto.Changeset.change(author, creator: true))
      publish!(announcement!(admin), [admin.email])

      assert queued_addresses() == [admin.email]

      assert [%{to: [nil: address]}] = send_emails()
      assert address == admin.email
    end

    test "sending the emails leaves the announcement unread", %{author: author, anna: anna} do
      announcement = publish!(announcement!(author))
      send_emails()

      for recipient <- Announcement.Public.list_recipients(announcement) do
        assert recipient.read_at == nil
      end

      assert [_] = NextAction.Public.list_next_actions(anna)
    end
  end

  describe "publishing a normal-priority announcement" do
    test "queues no email", %{author: author} do
      announcement = publish!(announcement!(author, %{priority: :normal}))

      assert length(Announcement.Public.list_recipients(announcement)) == 2
      assert dispatcher_jobs() == []
    end
  end

  describe "EmailTemplate.email/1" do
    test "links to the announcement page without anything that marks it read", %{
      author: author
    } do
      %{id: id} = announcement = announcement!(author)

      assert %Email.Model{subject: "Release notes", html_message: html} =
               Announcement.EmailTemplate.email(announcement)

      assert [url] = Regex.run(~r/href="([^"]+announcement[^"]*)"/, html, capture: :all_but_first)
      assert url == CoreWeb.Endpoint.url() <> "/announcement/#{id}"
    end

    test "is in Dutch in the nl locale", %{author: author} do
      email =
        Gettext.with_locale(CoreWeb.Gettext, "nl", fn ->
          Announcement.EmailTemplate.email(announcement!(author))
        end)

      assert email.html_message =~ "Lees deze aankondiging in Next"
      assert email.message =~ "Lees deze aankondiging in Next"
    end
  end

  describe "EmailTemplate.to_text/1" do
    test "keeps paragraphs, line breaks, list items and link addresses" do
      html =
        "<h1>Heading</h1><div>One<br>Two</div><blockquote>Quote</blockquote>" <>
          "<ol><li>First</li><li>Second</li></ol>" <>
          ~s(<div><a href="https://example.org">https://example.org</a> &lt;b&gt;</div>)

      assert Announcement.EmailTemplate.to_text(html) ==
               "Heading\n\nOne\nTwo\n\nQuote\n\n- First\n- Second\n\nhttps://example.org <b>"
    end
  end
end
