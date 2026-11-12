defmodule Systems.Rate.TestHelper do
  @moduledoc """
  Rate counters count in fixed windows that start on the minute, the hour or
  the day (`Systems.Rate.CounterModel`). A test that runs into the next window
  counts on from zero there, so a limit it filled no longer refuses.
  """

  alias Systems.Rate

  @doc """
  Waits for the next window of `window_seconds` when less than `margin_ms` of
  the current one is left on the counters' clock. Choose a margin far longer
  than the test takes and shorter than its timeout. Returns `:ok`, so it can be
  a `setup` callback.
  """
  def wait_out_window_end(window_seconds, margin_ms \\ 10_000)
      when is_integer(window_seconds) and window_seconds > 0 and is_integer(margin_ms) do
    window_ms = window_seconds * 1000
    now_ms = Rate.Private.datetime_now() |> DateTime.to_unix(:millisecond)
    left_ms = window_ms - rem(now_ms, window_ms)

    if left_ms < margin_ms, do: Process.sleep(left_ms)
    :ok
  end
end
