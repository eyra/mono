defmodule Systems.Announcement.ReadTest do
  use Core.DataCase, async: true

  alias Core.Repo
  alias Systems.Announcement
  alias Systems.Announcement.NextActions.ReadAnnouncement
  alias Systems.NextAction

  setup do
    author = Factories.insert!(:admin)
    user = Factories.insert!(:creator)

    {:ok, announcement} =
      Announcement.Public.create_announcement(author, %{
        kind: :release_notes,
        title: "Release notes October",
        summary: "What changed this month",
        body: "<div>New features</div>"
      })

    recipient =
      %Announcement.RecipientModel{announcement_id: announcement.id, user_id: user.id}
      |> Announcement.RecipientModel.changeset(%{})
      |> Repo.insert!()

    %{announcement: announcement, user: user, recipient: recipient}
  end

  describe "mark_read/1" do
    test "stamps read_at and clears the announcement's To-do", %{
      announcement: %{id: id},
      user: user,
      recipient: recipient
    } do
      create_to_do!(user, id)

      assert %{read_at: %DateTime{} = read_at} = Announcement.Public.mark_read(recipient)
      assert %{read_at: ^read_at} = Repo.reload!(recipient)
      assert NextAction.Public.count_next_actions(user) == 0
    end

    test "keeps the first read_at and clears a To-do that is there after reading", %{
      announcement: %{id: id},
      user: user,
      recipient: recipient
    } do
      %{read_at: read_at} = read = Announcement.Public.mark_read(recipient)
      create_to_do!(user, id)

      assert %{read_at: ^read_at} = Announcement.Public.mark_read(read)
      assert NextAction.Public.count_next_actions(user) == 0

      create_to_do!(user, id)

      assert %{read_at: ^read_at} = Announcement.Public.mark_read(recipient)
      assert %{read_at: ^read_at} = Repo.reload!(recipient)
      assert NextAction.Public.count_next_actions(user) == 0
    end
  end

  describe "ReadAnnouncement.to_view_model/2" do
    test "shows the announcement's current title and summary and opens its page", %{
      announcement: %{id: id} = announcement
    } do
      {:ok, _} = Announcement.Public.update_announcement(announcement, %{title: "Edited"})

      assert %{
               title: "Edited",
               description: "What changed this month",
               cta_label: "Read announcement",
               cta_action: %{type: :redirect, to: "/announcement/" <> path_id}
             } = ReadAnnouncement.to_view_model(1, ReadAnnouncement.params(id))

      assert path_id == to_string(id)
    end

    test "has a Dutch button", %{announcement: %{id: id}} do
      assert %{cta_label: "Lees aankondiging"} =
               Gettext.with_locale(CoreWeb.Gettext, "nl", fn ->
                 ReadAnnouncement.to_view_model(1, ReadAnnouncement.params(id))
               end)
    end
  end

  defp create_to_do!(user, announcement_id) do
    NextAction.Public.create_next_action(user, ReadAnnouncement,
      key: ReadAnnouncement.key(announcement_id),
      params: ReadAnnouncement.params(announcement_id)
    )
  end
end
