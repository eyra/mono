defmodule Next.Announcement.Public do
  @moduledoc """
  Create, change and read announcements and their recipients.

  A recipient row (`Next.Announcement.RecipientModel`) records that one user
  received an announcement and when they read it. Only users with a recipient
  row may open an announcement (`get_received/2`).
  """
  import Ecto.Query, warn: false
  import Next.Announcement.Queries

  alias Core.Repo
  alias Next.Announcement
  alias Systems.Account.User

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

  @doc "The recipient rows of `announcement`."
  def list_recipients(%Announcement.Model{} = announcement, preload \\ []) do
    recipient_query(announcement)
    |> order_by([recipient: r], asc: r.id)
    |> Repo.all()
    |> Repo.preload(preload)
  end
end
