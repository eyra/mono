defmodule Systems.Announcement.PageTest do
  use CoreWeb.ConnCase, async: false
  use Core.FeatureFlags.Test

  import ExUnit.CaptureLog
  import Phoenix.LiveViewTest

  alias Core.Repo
  alias CoreWeb.Endpoint
  alias Systems.Announcement
  alias Systems.Announcement.NextActions.ReadAnnouncement
  alias Systems.NextAction

  @published_at ~U[2026-10-28 09:00:00Z]

  setup do
    set_feature_flag(:announcements, true)

    author = Factories.insert!(:admin)
    creator = Factories.insert!(:creator)
    announcement = create_announcement!(author, "Release notes October")
    recipient = insert_recipient!(announcement, creator)

    %{author: author, announcement: announcement, creator: creator, recipient: recipient}
  end

  describe "a recipient" do
    setup ctx do
      {:ok, ctx} = login(ctx.creator, ctx)
      ctx
    end

    test "sees the title, the publication date and the cleaned body", %{
      conn: conn,
      announcement: %{id: id}
    } do
      {:ok, view, _html} = live(conn, ~p"/announcement/#{id}")

      assert view |> element("[data-testid=announcement-title]") |> render() =~
               "Release notes October"

      assert view |> element("[data-testid=announcement-published]") |> render() =~
               "Published on 28 October 2026"

      body = view |> element("[data-testid=announcement-body]") |> render()
      assert body =~ "<strong>features</strong>"
      assert body =~ ~s|<a href="https://example.com" target="_blank">the docs</a>|
    end

    test "marks it read on the first opening", %{conn: conn, announcement: %{id: id}} = ctx do
      {:ok, _view, _html} = live(conn, ~p"/announcement/#{id}")

      assert %{read_at: %DateTime{}} = Repo.reload!(ctx.recipient)
    end

    test "opening it again keeps the first read_at and clears a To-do that came back",
         %{conn: conn, announcement: %{id: id}} = ctx do
      {:ok, _view, _html} = live(conn, ~p"/announcement/#{id}")
      %{read_at: read_at} = Repo.reload!(ctx.recipient)

      create_to_do!(ctx.creator, id)

      {:ok, _view, _html} = live(conn, ~p"/announcement/#{id}")

      assert %{read_at: ^read_at} = Repo.reload!(ctx.recipient)
      assert NextAction.Public.count_next_actions(ctx.creator) == 0
    end

    test "a plain HTTP fetch of the page leaves it unread and keeps the To-do",
         %{conn: conn, announcement: %{id: id}} = ctx do
      create_to_do!(ctx.creator, id)

      assert conn |> get(~p"/announcement/#{id}") |> html_response(200) =~
               "Release notes October"

      assert %{read_at: nil} = Repo.reload!(ctx.recipient)
      assert NextAction.Public.count_next_actions(ctx.creator) == 1
    end

    test "clears its To-do and refreshes Desktop and the To-do counter", %{
      conn: conn,
      announcement: %{id: id},
      creator: %{id: creator_id} = creator
    } do
      create_to_do!(creator, id)
      {:ok, desktop, html} = live(conn, ~p"/desktop")
      assert html =~ "Release notes October"

      Endpoint.subscribe("next_actions:#{creator_id}")
      {:ok, _view, _html} = live(conn, ~p"/announcement/#{id}")

      assert_receive %Phoenix.Socket.Broadcast{event: "next_actions_updated"}
      assert NextAction.Public.count_next_actions(creator) == 0
      refute render(desktop) =~ "Release notes October"
    end

    test "leaves the To-dos of other announcements", %{
      conn: conn,
      announcement: %{id: id},
      author: author,
      creator: creator
    } do
      %{id: other_id} = create_announcement!(author, "Release notes November")
      create_to_do!(creator, id)
      create_to_do!(creator, other_id)

      {:ok, _view, _html} = live(conn, ~p"/announcement/#{id}")

      assert NextAction.Public.next_best_action_for_key(creator, ReadAnnouncement.key(other_id))
      refute NextAction.Public.next_best_action_for_key(creator, ReadAnnouncement.key(id))
    end

    test "opens it without a To-do", %{conn: conn, announcement: %{id: id}} = ctx do
      assert NextAction.Public.count_next_actions(ctx.creator) == 0

      {:ok, _view, _html} = live(conn, ~p"/announcement/#{id}")

      assert %{read_at: %DateTime{}} = Repo.reload!(ctx.recipient)
    end

    test "opens it with a timezone the server doesn't know", %{
      conn: conn,
      announcement: %{id: id},
      recipient: recipient
    } do
      capture_log(fn ->
        {:ok, view, _html} =
          conn
          |> put_connect_params(%{"timezone" => "Nope/Zone"})
          |> live(~p"/announcement/#{id}")

        assert view |> element("[data-testid=announcement-published]") |> render() =~
                 "Published on 28 October 2026"
      end)

      assert %{read_at: %DateTime{}} = Repo.reload!(recipient)
    end
  end

  describe "not found" do
    test "for a user who did not receive it", %{conn: conn, announcement: %{id: id}} = ctx do
      other = Factories.insert!(:creator)
      create_to_do!(other, id)
      conn = sign_in(conn, other)

      assert_error_sent(404, fn -> get(conn, ~p"/announcement/#{id}") end)
      assert NextAction.Public.count_next_actions(other) == 1
      assert %{read_at: nil} = Repo.reload!(ctx.recipient)
    end

    test "while the feature flag is off", %{conn: conn, announcement: %{id: id}} = ctx do
      set_feature_flag(:announcements, false)
      conn = sign_in(conn, ctx.creator)

      assert_error_sent(404, fn -> get(conn, ~p"/announcement/#{id}") end)
      assert %{read_at: nil} = Repo.reload!(ctx.recipient)
    end

    test "for an announcement that is not published", %{conn: conn} = ctx do
      draft = create_announcement!(ctx.author, "Draft", nil)
      recipient = insert_recipient!(draft, ctx.creator)
      conn = sign_in(conn, ctx.creator)

      assert_error_sent(404, fn -> get(conn, ~p"/announcement/#{draft.id}") end)
      assert %{read_at: nil} = Repo.reload!(recipient)
    end

    test "for an id that is not a number", %{conn: conn} = ctx do
      conn = sign_in(conn, ctx.creator)

      assert_error_sent(404, fn -> get(conn, "/announcement/latest") end)
    end
  end

  describe "a signed-out visitor" do
    test "signs in and comes back to the announcement", %{
      conn: conn,
      announcement: %{id: id}
    } do
      password = Factories.valid_user_password()
      creator = Factories.insert!(:member, %{password: password, creator: true})
      insert_recipient!(Announcement.Public.get_announcement!(id), creator)

      conn = get(conn, ~p"/announcement/#{id}")
      assert redirected_to(conn) == Core.SaaS.module().sign_in_page()

      conn =
        conn
        |> recycle()
        |> post("/user/session", %{
          "user" => %{"email" => creator.email, "password" => password}
        })

      assert redirected_to(conn) == "/announcement/#{id}"
    end
  end

  defp sign_in(conn, user) do
    {:ok, ctx} = login(user, %{conn: conn})
    Keyword.fetch!(ctx, :conn)
  end

  defp create_announcement!(author, title, published_at \\ @published_at) do
    {:ok, announcement} =
      Announcement.Public.create_announcement(author, %{
        kind: :release_notes,
        title: title,
        summary: "What changed this month",
        body:
          ~s|<div>New <strong>features</strong>, see <a href="https://example.com">the docs</a></div>|
      })

    announcement
    |> Ecto.Changeset.change(published_at: published_at)
    |> Repo.update!()
  end

  defp insert_recipient!(%{id: announcement_id}, %{id: user_id}) do
    %Announcement.RecipientModel{announcement_id: announcement_id, user_id: user_id}
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
