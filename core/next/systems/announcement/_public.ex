defmodule Systems.Announcement.Public do
  @moduledoc """
  Create, change and read announcements and their recipients.

  A recipient row (`Systems.Announcement.RecipientModel`) records that one user
  received an announcement and when they read it. Only users with a recipient
  row may open an announcement (`get_received/2`).
  """
  import Ecto.Query, warn: false
  import Systems.Announcement.Queries

  alias Core.Repo
  alias Systems.Account.User
  alias Systems.Announcement
  alias Systems.Announcement.NextActions.ReadAnnouncement
  alias Systems.NextAction

  @doc "Creates an announcement by `author`. The body is cleaned before it is stored."
  def create_announcement(%User{id: author_id}, attrs) do
    %Announcement.Model{author_id: author_id}
    |> Announcement.Model.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Changes an announcement. The body is cleaned before it is stored."
  def update_announcement(%Announcement.Model{} = announcement, attrs) do
    announcement
    |> Announcement.Model.changeset(attrs)
    |> Repo.update()
  end

  def get_announcement!(id, preload \\ []) do
    announcement_query()
    |> Repo.get!(id)
    |> Repo.preload(preload)
  end

  def get_announcement(id, preload \\ []) do
    announcement_query()
    |> Repo.get(id)
    |> Repo.preload(preload)
  end

  @doc """
  The announcements `user` received, as recipient rows with the announcement
  preloaded, newest publication first.
  """
  def list_received(%User{} = user) do
    received_query(user)
    |> preload([announcement: a], announcement: a)
    |> Repo.all()
  end

  @doc """
  The recipient row of `user` for the announcement with `announcement_id`, with
  the announcement preloaded, or `nil` when the user did not receive it.
  """
  def get_received(%User{} = user, announcement_id) do
    received_query(user)
    |> where([announcement: a], a.id == ^announcement_id)
    |> preload([announcement: a], announcement: a)
    |> Repo.one()
  end

  @doc """
  Marks the announcement read for the recipient and clears its To-do. Only
  the first call does this: `read_at` keeps the time of the first opening,
  and later calls change nothing. Returns the recipient with `read_at` set.
  """
  def mark_read(%Announcement.RecipientModel{id: id, read_at: nil} = recipient) do
    read_at = DateTime.utc_now() |> DateTime.truncate(:second)
    updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    recipient_query()
    |> where([recipient: r], r.id == ^id and is_nil(r.read_at))
    |> Repo.update_all(set: [read_at: read_at, updated_at: updated_at])
    |> case do
      {1, _} ->
        clear_to_do(recipient)
        %{recipient | read_at: read_at}

      {0, _} ->
        %{recipient | read_at: Repo.reload!(recipient).read_at}
    end
  end

  def mark_read(%Announcement.RecipientModel{} = recipient), do: recipient

  defp clear_to_do(%Announcement.RecipientModel{announcement_id: announcement_id} = recipient) do
    %{user: user} = Repo.preload(recipient, :user)

    NextAction.Public.clear_next_action(user, ReadAnnouncement,
      key: ReadAnnouncement.key(announcement_id)
    )
  end

  @doc "The recipient rows of `announcement`."
  def list_recipients(%Announcement.Model{} = announcement, preload \\ []) do
    recipient_query(announcement)
    |> order_by([recipient: r], asc: r.id)
    |> Repo.all()
    |> Repo.preload(preload)
  end
end
