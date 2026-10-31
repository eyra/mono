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

  @doc "Creates an announcement by `author`."
  def create_announcement(%User{id: author_id}, attrs) do
    %Announcement.Model{author_id: author_id}
    |> Announcement.Model.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Changes an announcement."
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

  @doc "All announcements, newest first."
  def list_announcements(preload \\ []) do
    announcement_query()
    |> order_by([announcement: a], desc: a.inserted_at, desc: a.id)
    |> Repo.all()
    |> Repo.preload(preload)
  end

  @doc """
  The number of recipients per announcement, as a map from announcement id to
  count. Announcements without recipients are left out.
  """
  def count_recipients(announcements) do
    ids = Enum.map(announcements, & &1.id)

    recipient_query()
    |> where([recipient: r], r.announcement_id in ^ids)
    |> group_by([recipient: r], r.announcement_id)
    |> select([recipient: r], {r.announcement_id, count(r.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc "The recipient rows of `announcement`."
  def list_recipients(%Announcement.Model{} = announcement, preload \\ []) do
    recipient_query(announcement)
    |> order_by([recipient: r], asc: r.id)
    |> Repo.all()
    |> Repo.preload(preload)
  end
end
