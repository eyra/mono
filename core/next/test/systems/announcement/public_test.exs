defmodule Systems.Announcement.PublicTest do
  use Core.DataCase, async: true

  alias Core.Repo
  alias Systems.Announcement

  @attrs %{
    kind: :release_notes,
    title: "Release notes",
    summary: "What changed this month",
    body: "<div>New <strong>features</strong></div>",
    priority: :high
  }

  setup do
    %{author: Factories.insert!(:admin)}
  end

  describe "create_announcement/2" do
    test "stores the announcement with its author", %{author: %{id: author_id} = author} do
      assert {:ok, %Announcement.Model{id: id}} =
               Announcement.Public.create_announcement(author, @attrs)

      assert %Announcement.Model{
               kind: :release_notes,
               title: "Release notes",
               summary: "What changed this month",
               body: "<div>New <strong>features</strong></div>",
               priority: :high,
               published_at: nil,
               author_id: ^author_id
             } = Announcement.Public.get_announcement!(id)
    end

    test "priority is normal unless given", %{author: author} do
      assert {:ok, %{priority: :normal}} =
               Announcement.Public.create_announcement(author, Map.delete(@attrs, :priority))
    end

    test "stores the cleaned body", %{author: author} do
      body = ~s'<div onclick="alert(1)">Hi<script>alert(1)</script></div>'

      assert {:ok, %{id: id}} =
               Announcement.Public.create_announcement(author, %{@attrs | body: body})

      assert %{body: "<div>Hi</div>"} = Announcement.Public.get_announcement!(id)
    end

    test "requires kind, title, summary and body", %{author: author} do
      assert {:error, changeset} = Announcement.Public.create_announcement(author, %{})

      assert %{
               kind: ["can't be blank"],
               title: ["can't be blank"],
               summary: ["can't be blank"],
               body: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "rejects a body that is empty after cleaning", %{author: author} do
      assert {:error, changeset} =
               Announcement.Public.create_announcement(author, %{
                 @attrs
                 | body: "<script>alert(1)</script>"
               })

      assert %{body: ["can't be blank"]} = errors_on(changeset)
    end

    test "rejects a body with only a pasted image", %{author: author} do
      body =
        ~S|<div><figure data-trix-content-type="image" class="attachment"><img src="https://example.org/s.png"><figcaption class="attachment__caption"></figcaption></figure></div>|

      assert {:error, changeset} =
               Announcement.Public.create_announcement(author, %{@attrs | body: body})

      assert %{body: ["can't be blank"]} = errors_on(changeset)
    end

    test "rejects a title longer than 255 characters", %{author: author} do
      assert {:ok, _} =
               Announcement.Public.create_announcement(author, %{
                 @attrs
                 | title: String.duplicate("x", 255)
               })

      assert {:error, changeset} =
               Announcement.Public.create_announcement(author, %{
                 @attrs
                 | title: String.duplicate("x", 256)
               })

      assert %{title: ["should be at most 255 character(s)"]} = errors_on(changeset)
    end

    test "rejects an unknown kind or priority", %{author: author} do
      assert {:error, changeset} =
               Announcement.Public.create_announcement(author, %{
                 @attrs
                 | kind: :news,
                   priority: :urgent
               })

      assert %{kind: ["is invalid"], priority: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "database constraints" do
    test "reject an unknown kind" do
      assert_raise Postgrex.Error, ~r/kind_must_be_valid/, fn ->
        insert_raw_announcement(kind: "news")
      end
    end

    test "reject an unknown priority" do
      assert_raise Postgrex.Error, ~r/priority_must_be_valid/, fn ->
        insert_raw_announcement(priority: "urgent")
      end
    end

    test "allow one recipient row per user and announcement", %{author: author} do
      announcement = create_announcement(author)
      user = Factories.insert!(:creator)

      assert {:ok, _} = insert_recipient(announcement, user)
      assert {:error, changeset} = insert_recipient(announcement, user)
      assert %{announcement_id: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "update_announcement/2" do
    test "changes the text and stores the cleaned body", %{author: author} do
      announcement = create_announcement(author)

      assert {:ok, _} =
               Announcement.Public.update_announcement(announcement, %{
                 title: "Fixed title",
                 body: ~s'<div>Fixed <a href="javascript:alert(1)">link</a></div>'
               })

      assert %{title: "Fixed title", body: "<div>Fixed <a>link</a></div>"} =
               Announcement.Public.get_announcement!(announcement.id)
    end

    test "rejects a title longer than 255 characters", %{author: author} do
      announcement = create_announcement(author)

      assert {:error, changeset} =
               Announcement.Public.update_announcement(announcement, %{
                 title: String.duplicate("x", 256)
               })

      assert %{title: ["should be at most 255 character(s)"]} = errors_on(changeset)
    end
  end

  describe "get_announcement/2" do
    test "returns nil for an unknown id" do
      assert Announcement.Public.get_announcement(-1) == nil
    end

    test "preloads the author", %{author: %{id: author_id} = author} do
      %{id: id} = create_announcement(author)

      assert %{author: %{id: ^author_id}} =
               Announcement.Public.get_announcement(id, Announcement.Model.preload_graph(:down))
    end
  end

  describe "list_received/1" do
    test "lists the user's announcements, newest publication first, with read status",
         %{author: author} do
      user = Factories.insert!(:creator)
      other = Factories.insert!(:creator)

      older = create_announcement(author, ~U[2026-10-01 09:00:00Z])
      newer = create_announcement(author, ~U[2026-10-20 09:00:00Z])
      not_received = create_announcement(author, ~U[2026-10-25 09:00:00Z])

      {:ok, _} = insert_recipient(older, user, ~U[2026-10-02 10:00:00Z])
      {:ok, _} = insert_recipient(newer, user)
      {:ok, _} = insert_recipient(not_received, other)

      assert [
               %Announcement.RecipientModel{
                 read_at: nil,
                 announcement: %Announcement.Model{id: newer_id}
               },
               %Announcement.RecipientModel{
                 read_at: ~U[2026-10-02 10:00:00Z],
                 announcement: %Announcement.Model{id: older_id}
               }
             ] = Announcement.Public.list_received(user)

      assert newer_id == newer.id
      assert older_id == older.id
    end

    test "is empty for a user without announcements" do
      assert Announcement.Public.list_received(Factories.insert!(:creator)) == []
    end
  end

  describe "get_received/2" do
    test "returns the user's recipient row with the announcement", %{author: author} do
      user = Factories.insert!(:creator)
      %{id: id} = announcement = create_announcement(author)
      {:ok, _} = insert_recipient(announcement, user)

      assert %Announcement.RecipientModel{announcement: %Announcement.Model{id: ^id}} =
               Announcement.Public.get_received(user, id)
    end

    test "returns nil when the user did not receive the announcement", %{author: author} do
      announcement = create_announcement(author)
      {:ok, _} = insert_recipient(announcement, Factories.insert!(:creator))

      assert Announcement.Public.get_received(Factories.insert!(:creator), announcement.id) ==
               nil
    end
  end

  describe "list_recipients/2" do
    test "lists only that announcement's recipients", %{author: author} do
      announcement = create_announcement(author)
      other_announcement = create_announcement(author)
      %{id: first_id} = first = Factories.insert!(:creator)
      %{id: second_id} = second = Factories.insert!(:creator)

      {:ok, _} = insert_recipient(announcement, first)
      {:ok, _} = insert_recipient(announcement, second)
      {:ok, _} = insert_recipient(other_announcement, first)

      assert [%{user: %{id: ^first_id}}, %{user: %{id: ^second_id}}] =
               Announcement.Public.list_recipients(announcement, [:user])
    end
  end

  defp create_announcement(author, published_at \\ nil) do
    {:ok, announcement} = Announcement.Public.create_announcement(author, @attrs)

    announcement
    |> Ecto.Changeset.change(published_at: published_at)
    |> Repo.update!()
  end

  defp insert_recipient(%{id: announcement_id}, %{id: user_id}, read_at \\ nil) do
    %Announcement.RecipientModel{announcement_id: announcement_id, user_id: user_id}
    |> Announcement.RecipientModel.changeset(%{read_at: read_at})
    |> Repo.insert()
  end

  defp insert_raw_announcement(overrides) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    row =
      Map.merge(
        %{
          kind: "release_notes",
          title: "Title",
          summary: "Summary",
          body: "<div>Body</div>",
          priority: "normal",
          inserted_at: now,
          updated_at: now
        },
        Map.new(overrides)
      )

    Repo.insert_all("announcement", [row])
  end
end
