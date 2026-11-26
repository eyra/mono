defmodule Systems.License.Public do
  @moduledoc """
  Licenses support gives a user, each until an end date: `:publish` and
  `:pay_in`. A license counts until the end of its end date in Amsterdam time,
  unless support switched it off; after that it is off until support gives it
  again. A license until 30 November is on through 30 November 23:59 and off
  from 1 December 00:00, Amsterdam time.

  Pay-in is behind the `:panl_post_launch` flag: without it, only Publish is
  shown, saved or told about.

  The user is told about their licenses through notifications
  (`License.Notify`), shown as To-dos (`License.NextActions`): when support
  gives one or switches one off, from 14 days before its end date, and once its
  end date has passed.
  """
  use Mica.FeatureFlags

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Frameworks.Signal
  alias Mica.Repo
  alias Systems.Account.User
  alias Systems.Admin
  alias Systems.License
  alias Systems.Notify

  @periods [:days_30, :days_60, :days_90, :year_1]
  @timezone "Europe/Amsterdam"
  @reminder_days 14

  @doc "The licenses support gives here: Publish, and Pay-in behind `:panl_post_launch`."
  def licenses do
    if feature_enabled?(:panl_post_launch), do: [:publish, :pay_in], else: [:publish]
  end

  @doc "The date in Amsterdam at `now`: the day end dates are counted in."
  def today(%DateTime{} = now \\ DateTime.utc_now()),
    do: now |> DateTime.shift_zone!(@timezone) |> DateTime.to_date()

  @doc "The periods support picks a license's end date from, besides a custom date."
  def periods, do: @periods

  @doc "The end date of a license given on `today` for `period`."
  def end_date(period, today \\ today())
  def end_date(:days_30, today), do: Date.add(today, 30)
  def end_date(:days_60, today), do: Date.add(today, 60)
  def end_date(:days_90, today), do: Date.add(today, 90)
  def end_date(:year_1, today), do: Date.shift(today, year: 1)

  @doc "A license date as support and the user read it: `26 Nov 2026`."
  def format_date(%Date{} = date),
    do: date |> Timex.format!("%e %b %Y", :strftime) |> String.trim()

  @doc "Whether `user` has `license` at `now`: given, not switched off, not past its end date."
  def active?(%User{} = user, license, %DateTime{} = now \\ DateTime.utc_now()) do
    case get_current(user, license) do
      nil -> false
      record -> License.Model.active?(record, today(now))
    end
  end

  @doc "The newest record of `user`'s `license`, its current state, or `nil` when never given."
  def get_current(%User{id: user_id}, license, preload \\ []) do
    from(l in License.Model,
      where: l.user_id == ^user_id and l.license == ^license,
      order_by: [desc: l.granted_at, desc: l.id],
      limit: 1,
      preload: ^preload
    )
    |> Repo.one()
  end

  @doc "Every record of `user`'s licenses, newest first."
  def list_records(%User{id: user_id}, preload \\ []) do
    from(l in License.Model,
      where: l.user_id == ^user_id,
      order_by: [desc: l.granted_at, desc: l.id],
      preload: ^preload
    )
    |> Repo.all()
  end

  @doc "The ids of the users who have `license` at `now`."
  def list_user_ids(license, %DateTime{} = now \\ DateTime.utc_now()) do
    today = today(now)

    current =
      from(l in License.Model,
        where: l.license == ^license,
        distinct: l.user_id,
        order_by: [asc: l.user_id, desc: l.granted_at, desc: l.id]
      )

    from(l in subquery(current),
      where: is_nil(l.revoked_at) and l.valid_until >= ^today,
      select: l.user_id
    )
    |> Repo.all()
  end

  @doc """
  Gives `user` `license` until `valid_until`, recorded as given by `granted_by`
  (`nil`: given by no one, such as a seed or the transition). Doesn't check who
  gives it; support goes through `save/4`.
  """
  def grant(%User{} = user, license, %Date{} = valid_until, granted_by \\ nil) do
    user
    |> License.Model.grant_changeset(license, valid_until, granted_by)
    |> Repo.insert()
  end

  @doc """
  Saves the changes support made to `user`'s licenses in the Licenses dialog:
  `%{license => {:on, end_date} | :off}`. `{:on, end_date}` gives the license,
  or gives it again, until `end_date`, which must lie after today in
  Amsterdam; `:off` switches it off when it is on. Each change is recorded with `by` and the time.

  Only system admins save licenses: anyone else gets `{:error, :forbidden}`
  and nothing changes. A license not in `licenses/0` (Pay-in without
  `:panl_post_launch`) is `{:error, {:unknown_license, license}}`, an end date
  that isn't after today `{:error, {:end_date_not_in_future, license}}`.

  Each license given or switched off is told to `user` by a job inserted in
  the same transaction (`License.TellWorker`, `tell_current/3`): it runs once
  the save is committed, and not at all when the save is rolled back.
  """
  def save(%User{} = by, %User{} = user, changes, %DateTime{} = now \\ DateTime.utc_now())
      when is_map(changes) do
    today = today(now)

    with :ok <- check_admin(by),
         :ok <- validate(changes, today) do
      changes
      |> Enum.reduce(Multi.new(), fn {license, change}, multi ->
        multi
        |> add_change(user, license, change, by, today)
        |> add_tell(user, license, by)
      end)
      |> Signal.Public.multi_dispatch({:license, :updated}, message: %{user: user})
      |> Repo.commit()
      |> case do
        {:ok, _results} ->
          :ok

        {:error, _operation, reason, _changes} ->
          {:error, reason}
      end
    end
  end

  defp check_admin(by) do
    if Admin.Public.admin?(by), do: :ok, else: {:error, :forbidden}
  end

  defp validate(changes, today) do
    licenses = licenses()

    Enum.reduce_while(changes, :ok, fn {license, change}, :ok ->
      case validate_change(license in licenses, change, today) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, {reason, license}}}
      end
    end)
  end

  defp validate_change(false, _change, _today), do: {:error, :unknown_license}
  defp validate_change(true, :off, _today), do: :ok

  defp validate_change(true, {:on, %Date{} = end_date}, today) do
    if Date.after?(end_date, today), do: :ok, else: {:error, :end_date_not_in_future}
  end

  defp validate_change(true, _change, _today), do: {:error, :invalid_change}

  defp add_change(multi, user, license, {:on, end_date}, by, _today) do
    Multi.insert(multi, license, License.Model.grant_changeset(user, license, end_date, by))
  end

  defp add_change(multi, user, license, :off, by, today) do
    Multi.run(multi, license, fn _repo, _ -> revoke(get_current(user, license), by, today) end)
  end

  defp revoke(nil, _by, _today), do: {:ok, nil}

  # `{:ok, nil}`: nothing to switch off, so nothing changed.
  defp revoke(record, by, today) do
    if License.Model.active?(record, today),
      do: Repo.update(License.Model.revoke_changeset(record, by)),
      else: {:ok, nil}
  end

  # A license the save changed (its change has a result) is told by a job
  # inserted in the same transaction (`License.TellWorker`).
  defp add_tell(multi, user, license, by) do
    Multi.run(multi, {:tell, license}, fn _repo, changes ->
      case Map.fetch!(changes, license) do
        nil -> {:ok, nil}
        _changed -> Oban.insert(License.TellWorker.new_tell(user, license, by))
      end
    end)
  end

  @doc """
  Tells `user` how their `license` stands now that `by` changed it: given
  until its end date, or switched off (`License.Notify`, shown as a To-do).
  Run by `License.TellWorker` after a save. The current record is read under
  the license's lock (`with_lock/3`), so of two saves at once the user is told
  the newest state; a record already told about isn't told again, so running
  it twice tells once.
  """
  def tell_current(%User{} = user, license, by \\ nil) do
    with_lock(user, license, fn ->
      case get_current(user, license) do
        %License.Model{revoked_at: nil, valid_until: valid_until} = record ->
          tell_once(user, license, {:given, valid_until}, record, by)

        %License.Model{} = record ->
          tell_once(user, license, :switched_off, record, by)

        nil ->
          :ok
      end
    end)
  end

  defp tell_once(user, license, message, %License.Model{id: record_id}, by) do
    unless told_record?(user, license, message, record_id),
      do: tell(user, license, message, record_id, by)

    :ok
  end

  defp told_record?(%User{id: user_id}, license, message, record_id) do
    {type, _metadata} = event(message)

    type
    |> Notify.Public.list_recorded(correlation_id(license), user_id)
    |> Enum.any?(&match?(%{metadata: %{"record_id" => ^record_id}}, &1))
  end

  @doc """
  The daily job's tell: tells `user` `message` (`{:reminder, end_date}` or
  `{:ended, end_date}`) about the record `record_id` it read, unless, under the
  license's lock, that record is no longer the license's current one, was
  switched off, or was told this already. So a license support gives again or
  switches off while the job runs keeps the To-do the save told. Returns
  `:told` or `:skipped`.
  """
  def tell_if_current(%User{} = user, license, record_id, {type, valid_until} = message) do
    with_lock(user, license, fn ->
      with %License.Model{id: ^record_id, revoked_at: nil} <- get_current(user, license),
           false <- told?(user, license, type, valid_until) do
        tell(user, license, message, record_id, nil)
        :told
      else
        _ -> :skipped
      end
    end)
  end

  # Tells `user` about their `license`: a notification (`License.Notify`)
  # shown as a To-do (`License.NextActions`) about the license record
  # `record_id`, recorded as from `by` (`nil`: the daily job). The notifications about that license the user hasn't seen yet
  # are marked seen first, so it replaces the To-do they had about it. Only
  # called under the license's lock.
  defp tell(user, license, message, record_id, by) do
    correlation_id = correlation_id(license)
    {:ok, _} = Notify.Public.mark_seen(user, correlation_id: correlation_id)
    {type, metadata} = event(message)
    metadata = Map.merge(metadata, %{"license" => to_string(license), "record_id" => record_id})

    Notify.Public.record_event(%Notify.EventAttrs{
      type: type,
      subject_user: user,
      actor_user: by,
      correlation_id: correlation_id,
      metadata: metadata,
      source: __MODULE__
    })
  end

  # Runs `fun` holding a Postgres advisory lock on `user`'s `license`, so the
  # tells about one license, from saves on any machine and from the daily job,
  # happen one after the other. A session lock on this process's connection,
  # not a transaction: each step commits as it happens, so the signals that
  # refresh open pages never see uncommitted rows.
  defp with_lock(%User{id: user_id}, license, fun) do
    lock = [lock_key(license), user_id]

    Repo.checkout(fn ->
      Repo.query!("SELECT pg_advisory_lock($1::int, $2::int)", lock)

      try do
        fun.()
      after
        Repo.query!("SELECT pg_advisory_unlock($1::int, $2::int)", lock)
      end
    end)
  end

  defp lock_key(license), do: :erlang.phash2({__MODULE__, license})

  defp correlation_id(license), do: "license:#{license}"

  defp event({:given, valid_until}), do: {:license_given, end_date_metadata(valid_until)}
  defp event(:switched_off), do: {:license_switched_off, %{}}
  defp event({:reminder, valid_until}), do: {:license_reminder, end_date_metadata(valid_until)}
  defp event({:ended, valid_until}), do: {:license_ended, end_date_metadata(valid_until)}

  defp event_type(:reminder), do: :license_reminder
  defp event_type(:ended), do: :license_ended

  defp end_date_metadata(valid_until), do: %{"valid_until" => Date.to_iso8601(valid_until)}

  defp told?(%User{id: user_id}, license, type, valid_until) do
    end_date = Date.to_iso8601(valid_until)

    type
    |> event_type()
    |> Notify.Public.list_recorded(correlation_id(license), user_id)
    |> Enum.any?(&match?(%{metadata: %{"valid_until" => ^end_date}}, &1))
  end

  @doc """
  Reminds each user whose license ends within 14 days, counted in Amsterdam
  at `now`, and who wasn't reminded of that end date yet: a To-do that opens
  the helpdesk page (`tell_if_current/4`). Every license counts, also one
  given by no one (the transition). Run daily by `License.ReminderWorker`;
  returns the number of users reminded.
  """
  def remind(%DateTime{} = now \\ DateTime.utc_now()) do
    today = today(now)
    until = Date.add(today, @reminder_days)

    tell_each(:reminder, fn query ->
      from(l in query, where: l.valid_until >= ^today and l.valid_until <= ^until)
    end)
  end

  @doc """
  Tells each user whose license has passed its end date, counted in Amsterdam
  at `now`, and who wasn't told yet: a To-do that says which license ended and
  opens the helpdesk page. It replaces the reminder (`tell_if_current/4`). A
  license support switched off isn't told again. Run daily by
  `License.ReminderWorker`; returns the number of users told.
  """
  def tell_ended(%DateTime{} = now \\ DateTime.utc_now()) do
    today = today(now)

    tell_each(:ended, fn query ->
      from(l in query, where: l.valid_until < ^today)
    end)
  end

  # Tells `type` about each license in `licenses/0` whose current record is on
  # and passes `filter`. The users already told about that end date are left
  # out up front (seen or not); `tell_if_current/4` checks again under the lock.
  defp tell_each(type, filter) do
    licenses()
    |> Enum.map(&tell_each(type, &1, filter))
    |> Enum.sum()
  end

  defp tell_each(type, license, filter) do
    told = told(type, license)

    license
    |> list_current(filter)
    |> Enum.reject(&MapSet.member?(told, {&1.user.id, Date.to_iso8601(&1.valid_until)}))
    |> Enum.count(fn %{user: user, id: id, valid_until: valid_until} ->
      tell_if_current(user, license, id, {type, valid_until}) == :told
    end)
  end

  defp told(type, license) do
    type
    |> event_type()
    |> Notify.Public.list_recorded(correlation_id(license))
    |> MapSet.new(fn %{subject_user_id: user_id, metadata: metadata} ->
      {user_id, metadata["valid_until"]}
    end)
  end

  defp list_current(license, filter) do
    current =
      from(l in License.Model,
        where: l.license == ^license,
        distinct: l.user_id,
        order_by: [asc: l.user_id, desc: l.granted_at, desc: l.id]
      )

    from(l in subquery(current),
      join: u in User,
      on: u.id == l.user_id,
      where: is_nil(l.revoked_at),
      select: %{user: u, id: l.id, valid_until: l.valid_until}
    )
    |> filter.()
    |> Repo.all()
  end
end
