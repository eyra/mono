defmodule Systems.Rate.CounterModel do
  @moduledoc """
  A count of events per key in fixed time windows, kept in the database so
  every node shares it and it survives restarts and deploys. The key is
  stored hashed.
  """
  use Ecto.Schema
  import Ecto.Query

  @primary_key false
  schema "rate_counters" do
    field(:key, :binary, primary_key: true)
    field(:window_start, :utc_datetime, primary_key: true)
    field(:expires_at, :utc_datetime)
    field(:count, :integer, default: 0)
  end

  def row(key, window_seconds, %DateTime{} = now) do
    window_start = window_start(now, window_seconds)

    %{
      key: hash_key(key, window_seconds),
      window_start: window_start,
      expires_at: DateTime.add(window_start, window_seconds),
      count: 1
    }
  end

  def count_query(key, window_seconds, %DateTime{} = now) do
    from(c in __MODULE__,
      where: c.key == ^hash_key(key, window_seconds),
      where: c.window_start == ^window_start(now, window_seconds),
      select: c.count
    )
  end

  def decrement_query(key, window_seconds, %DateTime{} = now) do
    from(c in __MODULE__,
      where: c.key == ^hash_key(key, window_seconds),
      where: c.window_start == ^window_start(now, window_seconds),
      where: c.count > 0
    )
  end

  def expired_query(%DateTime{} = now) do
    from(c in __MODULE__, where: c.expires_at <= ^DateTime.truncate(now, :second))
  end

  defp window_start(now, window_seconds) do
    unix = DateTime.to_unix(now)
    DateTime.from_unix!(unix - rem(unix, window_seconds))
  end

  defp hash_key(key, window_seconds), do: :crypto.hash(:sha256, "#{window_seconds}:#{key}")
end
