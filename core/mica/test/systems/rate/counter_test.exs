defmodule Systems.Rate.CounterTest do
  use Core.DataCase, async: true

  alias Core.Repo
  alias Systems.Rate
  alias Systems.Rate.CounterModel

  describe "increment_counter/2" do
    test "crashes on a window that isn't a positive number of seconds" do
      assert_raise FunctionClauseError, fn -> Rate.Public.increment_counter("k", 0) end
    end

    test "counts each event of a key in the window" do
      assert 1 = Rate.Public.increment_counter("k", 3600)
      assert 2 = Rate.Public.increment_counter("k", 3600)
      assert 3 = Rate.Public.increment_counter("k", 3600)
      assert 3 = Rate.Public.counter("k", 3600)
    end

    test "counts keys and window lengths apart" do
      Rate.Public.increment_counter("a", 3600)
      Rate.Public.increment_counter("a", 3600)
      Rate.Public.increment_counter("a", 86_400)
      Rate.Public.increment_counter("b", 3600)

      assert 2 = Rate.Public.counter("a", 3600)
      assert 1 = Rate.Public.counter("a", 86_400)
      assert 1 = Rate.Public.counter("b", 3600)
      assert 0 = Rate.Public.counter("c", 3600)
    end

    test "concurrent events are each counted once" do
      counts =
        1..20
        |> Enum.map(fn _ -> Task.async(fn -> Rate.Public.increment_counter("k", 60) end) end)
        |> Task.await_many()

      assert Enum.sort(counts) == Enum.to_list(1..20)
      assert 20 = Rate.Public.counter("k", 60)
    end

    test "doesn't store the key itself" do
      Rate.Public.increment_counter("someone@example.com", 3600)

      assert [%CounterModel{key: key}] = Repo.all(CounterModel)
      refute key =~ "someone@example.com"
    end
  end

  describe "delete_expired_counters/0" do
    test "deletes the counters of ended windows only" do
      Rate.Public.increment_counter("current", 3600)
      Rate.Public.increment_counter("ended", 3600)
      end_windows("ended", 3600)

      assert 1 = Rate.Public.delete_expired_counters()
      assert 1 = Rate.Public.counter("current", 3600)
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
