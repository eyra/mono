defmodule Systems.Rate.Public do
  use Core, :public

  alias Core.Repo
  alias Systems.Rate

  defmodule RateLimitError do
    defexception [:message]
  end

  def request_permission(service, client_id, packet_size) when is_atom(service) do
    request_permission(service |> Atom.to_string(), client_id, packet_size)
  end

  def request_permission(service, client_id, packet_size)
      when is_binary(service) and is_binary(client_id) and is_integer(packet_size) do
    case Systems.Rate.Server.request_permission(service, client_id, packet_size) do
      {:denied, reason} -> raise RateLimitError, reason
      _ -> :granted
    end
  end

  @doc """
  Counts one event for `key` in the current fixed window of `window_seconds`
  and returns the window's count, this event included.

  Unlike the quotas of `request_permission/3`, which each node keeps in
  memory, the counter is kept in the database: all nodes share it and it
  survives restarts and deploys.
  """
  def increment_counter(key, window_seconds)
      when is_binary(key) and is_integer(window_seconds) and window_seconds > 0 do
    row = Rate.CounterModel.row(key, window_seconds, Rate.Private.datetime_now())

    {1, [%{count: count}]} =
      Repo.insert_all(Rate.CounterModel, [row],
        on_conflict: [inc: [count: 1]],
        conflict_target: [:key, :window_start],
        returning: [:count]
      )

    count
  end

  @doc """
  Takes back one event of `key` in the current window of `window_seconds`,
  for an event `increment_counter/2` counted that didn't happen after all.
  Never goes below 0.
  """
  def decrement_counter(key, window_seconds)
      when is_binary(key) and is_integer(window_seconds) and window_seconds > 0 do
    Rate.CounterModel.decrement_query(key, window_seconds, Rate.Private.datetime_now())
    |> Repo.update_all(inc: [count: -1])

    :ok
  end

  @doc """
  The count of `key` in the current window of `window_seconds`, without
  counting an event.
  """
  def counter(key, window_seconds)
      when is_binary(key) and is_integer(window_seconds) and window_seconds > 0 do
    Rate.CounterModel.count_query(key, window_seconds, Rate.Private.datetime_now())
    |> Repo.one()
    |> Kernel.||(0)
  end

  @doc """
  Deletes the counters of windows that have ended. Returns the number of rows
  deleted.
  """
  def delete_expired_counters do
    {deleted_count, _} =
      Rate.Private.datetime_now()
      |> Rate.CounterModel.expired_query()
      |> Repo.delete_all()

    deleted_count
  end
end
