defmodule Systems.Rate.CounterTest do
  use Mica.DataCase, async: true

  alias Mica.Repo
  alias Systems.Rate
  alias Systems.Rate.CounterModel

  # Async test modules write rate_counters in parallel transactions; a shared
  # key makes their upserts wait on each other, in opposite order a deadlock.
  defp unique_key(name), do: "#{name}-#{System.unique_integer([:positive])}"

  # The shortest window here is a minute, and every hour and day starts on one.
  setup do: Rate.TestHelper.wait_out_window_end(60, 2_000)

  describe "increment_counter/2" do
    test "crashes on a window that isn't a positive number of seconds" do
      assert_raise FunctionClauseError, fn -> Rate.Public.increment_counter("k", 0) end
    end

    test "counts each event of a key in the window" do
      k = unique_key("k")

      assert 1 = Rate.Public.increment_counter(k, 3600)
      assert 2 = Rate.Public.increment_counter(k, 3600)
      assert 3 = Rate.Public.increment_counter(k, 3600)
      assert 3 = Rate.Public.counter(k, 3600)
    end

    test "counts keys and window lengths apart" do
      a = unique_key("a")
      b = unique_key("b")
      c = unique_key("c")

      Rate.Public.increment_counter(a, 3600)
      Rate.Public.increment_counter(a, 3600)
      Rate.Public.increment_counter(a, 86_400)
      Rate.Public.increment_counter(b, 3600)

      assert 2 = Rate.Public.counter(a, 3600)
      assert 1 = Rate.Public.counter(a, 86_400)
      assert 1 = Rate.Public.counter(b, 3600)
      assert 0 = Rate.Public.counter(c, 3600)
    end

    test "concurrent events are each counted once" do
      k = unique_key("k")

      counts =
        1..20
        |> Enum.map(fn _ -> Task.async(fn -> Rate.Public.increment_counter(k, 60) end) end)
        |> Task.await_many()

      assert Enum.sort(counts) == Enum.to_list(1..20)
      assert 20 = Rate.Public.counter(k, 60)
    end

    test "doesn't store the key itself" do
      email = unique_key("someone") <> "@example.com"
      Rate.Public.increment_counter(email, 3600)

      assert [%CounterModel{key: key}] = Repo.all(CounterModel)
      refute key =~ email
    end
  end

  describe "decrement_counter/2" do
    test "takes back one event" do
      k = unique_key("k")

      Rate.Public.increment_counter(k, 3600)
      Rate.Public.increment_counter(k, 3600)

      assert :ok = Rate.Public.decrement_counter(k, 3600)
      assert 1 = Rate.Public.counter(k, 3600)
    end

    test "never goes below 0" do
      k = unique_key("k")

      Rate.Public.increment_counter(k, 3600)
      Rate.Public.decrement_counter(k, 3600)
      Rate.Public.decrement_counter(k, 3600)

      assert 0 = Rate.Public.counter(k, 3600)
      assert 1 = Rate.Public.increment_counter(k, 3600)
    end

    test "does nothing for a key without a count" do
      none = unique_key("none")

      assert :ok = Rate.Public.decrement_counter(none, 3600)
      assert 0 = Rate.Public.counter(none, 3600)
    end
  end

  describe "delete_expired_counters/0" do
    test "deletes the counters of ended windows only" do
      current = unique_key("current")
      ended = unique_key("ended")

      Rate.Public.increment_counter(current, 3600)
      Rate.Public.increment_counter(ended, 3600)
      end_windows(ended, 3600)

      assert 1 = Rate.Public.delete_expired_counters()
      assert 1 = Rate.Public.counter(current, 3600)
      assert 1 = Repo.aggregate(CounterModel, :count)
    end
  end

  defp end_windows(key, window_seconds) do
    now = DateTime.utc_now()
    ended = DateTime.add(now, -window_seconds - 60) |> DateTime.truncate(:second)

    key
    |> Rate.CounterModel.count_query(window_seconds, now)
    |> Ecto.Query.exclude(:select)
    |> Repo.update_all(
      set: [window_start: ended, expires_at: DateTime.add(ended, window_seconds)]
    )
  end
end
