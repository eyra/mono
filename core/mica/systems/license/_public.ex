defmodule Systems.License.Public do
  @moduledoc """
  Licenses support gives a user, each until an end date: `:publish` and
  `:pay_in`. A license counts until the end of its end date in Amsterdam time,
  unless support switched it off; after that it is off until support gives it
  again. A license until 30 November is on through 30 November 23:59 and off
  from 1 December 00:00, Amsterdam time.

  Pay-in is behind the `:panl_post_launch` flag: without it, only Publish is
  shown, saved or reminded of.

  The user is told about their licenses through To-dos (`License.NextActions`):
  when support gives one or switches one off, and from 14 days before its end
  date.
  """
  use Mica.FeatureFlags

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Frameworks.Signal
  alias Mica.Repo
  alias Systems.Account.User
  alias Systems.Admin
  alias Systems.License
  alias Systems.NextAction

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

  Once saved, `user` is told about each license given or switched off
  (`tell/3`).
  """
  def save(%User{} = by, %User{} = user, changes, %DateTime{} = now \\ DateTime.utc_now())
      when is_map(changes) do
    today = today(now)

    with :ok <- check_admin(by),
         :ok <- validate(changes, today) do
      changes
      |> Enum.reduce(Multi.new(), fn {license, change}, multi ->
        add_change(multi, user, license, change, by, today)
      end)
      |> Signal.Public.multi_dispatch({:license, :updated}, message: %{user: user})
      |> Repo.commit()
      |> case do
        {:ok, results} ->
          tell_saved(user, Map.keys(changes), results)

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

  defp tell_saved(user, licenses, results),
    do: Enum.each(licenses, &tell_saved(user, Map.fetch!(results, &1)))

  defp tell_saved(_user, nil), do: :ok

  defp tell_saved(user, %License.Model{
         license: license,
         revoked_at: nil,
         valid_until: valid_until
       }),
       do: tell(user, license, {:given, valid_until})

  defp tell_saved(user, %License.Model{license: license}), do: tell(user, license, :switched_off)

  @doc """
  Tells `user` about their `license` with a To-do (`License.NextActions`):
  `{:given, end_date}`, `:switched_off` or `{:reminder, end_date}`. It
  replaces the To-do they had about that license.
  """
  def tell(%User{} = user, license, message) do
    key = License.NextActions.key(license)

    Enum.each(
      License.NextActions.types(),
      &NextAction.Public.clear_next_action(user, &1, key: key)
    )

    {type, params, opts} = next_action(message)

    NextAction.Public.create_next_action(
      user,
      type,
      [key: key, params: Map.put(params, "license", key)] ++ opts
    )
  end

  defp next_action({:given, valid_until}),
    do: {License.NextActions.Given, %{"valid_until" => Date.to_iso8601(valid_until)}, []}

  defp next_action(:switched_off), do: {License.NextActions.SwitchedOff, %{}, []}

  defp next_action({:reminder, valid_until}),
    do:
      {License.NextActions.Reminder, %{"valid_until" => Date.to_iso8601(valid_until)},
       [priority: :high]}

  @doc """
  Reminds each user whose license ends within 14 days, counted in Amsterdam
  at `now`, and who wasn't reminded yet: a To-do that opens the helpdesk page,
  until support gives the license again (`tell/3`). Every license counts, also
  one given by no one (the transition). Run daily by `License.ReminderWorker`;
  returns the number of users reminded.
  """
  def remind(%DateTime{} = now \\ DateTime.utc_now()) do
    today = today(now)

    for license <- licenses(), record <- list_ending(license, today), reduce: 0 do
      count ->
        tell(record.user, license, {:reminder, record.valid_until})
        count + 1
    end
  end

  # The current records of `license` that are on and end within 14 days of
  # `today`, of the users without a reminder about it.
  defp list_ending(license, today) do
    reminded =
      NextAction.Public.list_user_ids(
        License.NextActions.Reminder,
        License.NextActions.key(license)
      )

    current =
      from(l in License.Model,
        where: l.license == ^license,
        distinct: l.user_id,
        order_by: [asc: l.user_id, desc: l.granted_at, desc: l.id]
      )

    from(l in subquery(current),
      join: u in User,
      on: u.id == l.user_id,
      where: is_nil(l.revoked_at) and l.valid_until >= ^today,
      where: l.valid_until <= ^Date.add(today, @reminder_days),
      where: l.user_id not in ^reminded,
      select: %{user: u, valid_until: l.valid_until}
    )
    |> Repo.all()
  end
end
