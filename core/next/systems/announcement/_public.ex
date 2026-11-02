defmodule Systems.Announcement.Public do
  @moduledoc """
  Create, change and read announcements and their recipients.

  A recipient row (`Systems.Announcement.RecipientModel`) records that one user
  received an announcement and when they read it. Only users with a recipient
  row may open a published announcement (`get_received/2`).
  """
  import Ecto.Query, warn: false
  import Systems.Announcement.Queries

  alias Core.Repo
  alias Ecto.Multi
  alias Frameworks.Signal
  alias Systems.Account.User
  alias Systems.Admin
  alias Systems.Announcement
  alias Systems.Announcement.NextActions.ReadAnnouncement
  alias Systems.NextAction

  @doc "Creates an announcement by `author`."
  def create_announcement(%User{id: author_id}, attrs) do
    %Announcement.Model{author_id: author_id}
    |> Announcement.Model.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Changes an announcement and dispatches `{:announcement, :updated}`, so the
  pages that show it refresh.
  """
  def update_announcement(%Announcement.Model{} = announcement, attrs) do
    announcement
    |> Announcement.Model.changeset(attrs)
    |> Repo.update()
    |> tap(fn
      {:ok, announcement} ->
        Signal.Public.dispatch!({:announcement, :updated}, %{announcement: announcement})

      {:error, _} ->
        :ok
    end)
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
  The published announcements `user` received, as recipient rows with the announcement
  preloaded, newest publication first. `limit: n` returns only the `n` newest.
  """
  def list_received(%User{} = user, opts \\ []) do
    received_query(user)
    |> limit_to(Keyword.get(opts, :limit))
    |> preload([announcement: a], announcement: a)
    |> Repo.all()
  end

  defp limit_to(query, nil), do: query
  defp limit_to(query, limit), do: limit(query, ^limit)

  @doc """
  The recipient row of `user` for the announcement with `announcement_id`, with
  the announcement preloaded, or `nil` when the user did not receive it or it
  is not published.
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

  @audience_filters [:verified, :unverified]

  @doc """
  The filters that narrow the audience of an announcement. The audience is
  always creators; these come on top, combined with AND.
  """
  def audience_filters, do: @audience_filters

  @doc """
  The ids of the users an announcement for the audience of `filters` and
  `query` reaches: creators with a confirmed account that match every filter
  and every word of the search, with the matching of Admin → Users
  (`Systems.Admin.Public.list_matching_users/2`). Filters other than
  `audience_filters/0` are ignored.
  """
  def list_audience_ids(filters, query) do
    filters = [:creator | Enum.filter(filters, &(&1 in @audience_filters))]

    Admin.Public.list_matching_users(filters, query)
    |> Enum.filter(&confirmed?/1)
    |> Enum.map(fn %User{id: id} -> id end)
  end

  defp confirmed?(%User{confirmed_at: confirmed_at}), do: confirmed_at != nil

  @doc """
  Publishes an unpublished announcement to the audience of `filters` and
  `query` (`list_audience_ids/2`). The audience is resolved here, once, and
  stored on the announcement; a job then gives every recipient a recipient
  row and a To-do (`deliver_announcement/1`).

  Returns `{:error, :no_recipients}` when the audience is empty and
  `{:error, :already_published}` when it was published before.
  """
  def publish_announcement(%Announcement.Model{published_at: nil} = announcement, filters, query) do
    case list_audience_ids(filters, query) do
      [] -> {:error, :no_recipients}
      recipient_ids -> publish(announcement, recipient_ids)
    end
  end

  def publish_announcement(%Announcement.Model{}, _filters, _query),
    do: {:error, :already_published}

  defp publish(%Announcement.Model{id: id}, recipient_ids) do
    Multi.new()
    |> Multi.run(:announcement, fn _repo, _ -> fix_audience(id, recipient_ids) end)
    |> Multi.run(:job, fn _repo, _ ->
      %{"announcement_id" => id}
      |> Announcement.DeliverJob.new()
      |> Oban.insert()
    end)
    |> Repo.commit()
    |> case do
      {:ok, %{announcement: announcement}} -> {:ok, announcement}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  # Only an unpublished announcement gets an audience, so publishing it twice
  # at the same moment publishes it once.
  defp fix_audience(id, recipient_ids) do
    published_at = DateTime.utc_now() |> DateTime.truncate(:second)
    updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    announcement_query()
    |> where([announcement: a], a.id == ^id and is_nil(a.published_at))
    |> select([announcement: a], a)
    |> Repo.update_all(
      set: [published_at: published_at, recipient_ids: recipient_ids, updated_at: updated_at]
    )
    |> case do
      {1, [announcement]} -> {:ok, announcement}
      {0, _} -> {:error, :already_published}
    end
  end

  @doc """
  Gives every recipient of a published announcement a recipient row and a
  To-do, with one insert for the rows and batched inserts for the To-dos.
  Recipients who already have a row are skipped, so running it again adds
  nothing. Users deleted since publication are left out. Returns
  `{:ok, count}` with the number of recipients added.
  """
  def deliver_announcement(announcement_id) do
    case get_announcement(announcement_id) do
      %Announcement.Model{published_at: nil} -> {:ok, 0}
      %Announcement.Model{} = announcement -> deliver(announcement)
      nil -> {:ok, 0}
    end
  end

  defp deliver(%Announcement.Model{id: id} = announcement) do
    Multi.new()
    |> Multi.run(:user_ids, fn _repo, _ -> {:ok, insert_recipients(announcement)} end)
    |> Multi.run(:next_actions, fn _repo, %{user_ids: user_ids} ->
      {:ok,
       NextAction.Public.create_next_actions(user_ids, ReadAnnouncement,
         key: ReadAnnouncement.key(id),
         params: ReadAnnouncement.params(id)
       )}
    end)
    |> Repo.commit()
    |> case do
      {:ok, %{user_ids: user_ids}} -> {:ok, length(user_ids)}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  defp insert_recipients(%Announcement.Model{id: id, recipient_ids: recipient_ids}) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    users =
      from(u in User,
        where: u.id in ^recipient_ids,
        select: %{
          announcement_id: type(^id, :id),
          user_id: u.id,
          inserted_at: type(^now, :naive_datetime),
          updated_at: type(^now, :naive_datetime)
        }
      )

    {_count, rows} =
      Repo.insert_all(Announcement.RecipientModel, users,
        on_conflict: :nothing,
        conflict_target: [:announcement_id, :user_id],
        returning: [:user_id]
      )

    Enum.map(rows, fn %{user_id: user_id} -> user_id end)
  end

  @doc """
  Marks the announcement read for the recipient and clears its To-do.
  `read_at` is set only once and keeps the time of the first opening. The
  To-do is cleared on every call, so one that is left or comes back after
  the first opening goes too. Returns the recipient with `read_at` set.
  """
  def mark_read(%Announcement.RecipientModel{} = recipient) do
    recipient = stamp_read_at(recipient)
    clear_to_do(recipient)
    recipient
  end

  defp stamp_read_at(%Announcement.RecipientModel{id: id, read_at: nil} = recipient) do
    read_at = DateTime.utc_now() |> DateTime.truncate(:second)
    updated_at = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    recipient_query()
    |> where([recipient: r], r.id == ^id and is_nil(r.read_at))
    |> Repo.update_all(set: [read_at: read_at, updated_at: updated_at])
    |> case do
      {1, _} -> %{recipient | read_at: read_at}
      {0, _} -> %{recipient | read_at: Repo.reload!(recipient).read_at}
    end
  end

  defp stamp_read_at(%Announcement.RecipientModel{} = recipient), do: recipient

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
