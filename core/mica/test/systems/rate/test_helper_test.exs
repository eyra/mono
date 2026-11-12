defmodule Systems.Rate.TestHelperTest do
  # Mocks the counters' clock for every process, so it runs apart from the
  # async rate tests.
  use Mica.DataCase, async: false

  import Mock

  alias Systems.Account.AuthCodeLimits
  alias Systems.Rate

  @remote_ip "203.0.113.10"

  # A request reads the clock 5 times.
  @ms_per_reading 10

  # Reads `start` first and then runs on: real time since that first reading
  # plus 10 ms per reading, so a window end falls between the same readings
  # however fast or slow the machine is.
  defp clock_from(start) do
    # 1: the number of readings, 2: the time of the first one.
    state = :atomics.new(2, [])

    fn ->
      now = System.monotonic_time(:millisecond)
      readings = :atomics.add_get(state, 1, 1)
      if readings == 1, do: :atomics.put(state, 2, now)

      elapsed = now - :atomics.get(state, 2) + (readings - 1) * @ms_per_reading
      DateTime.add(start, elapsed, :millisecond)
    end
  end

  defp before?(a, b), do: DateTime.compare(a, b) == :lt

  describe "wait_out_window_end/2" do
    test "inside the margin, waits into the next window" do
      with_mock Rate.Private, datetime_now: clock_from(~U[2026-01-01 10:59:59.800Z]) do
        assert :ok = Rate.TestHelper.wait_out_window_end(60, 1_000)
        refute before?(Rate.Private.datetime_now(), ~U[2026-01-01 11:00:00Z])
      end
    end

    test "outside the margin, doesn't wait" do
      with_mock Rate.Private, datetime_now: clock_from(~U[2026-01-01 10:59:55Z]) do
        assert :ok = Rate.TestHelper.wait_out_window_end(60, 1_000)
        assert before?(Rate.Private.datetime_now(), ~U[2026-01-01 11:00:00Z])
      end
    end

    # Without the wait, the hour ends during the 2nd or 3rd of the 10 requests.
    test "a filled limit still refuses when the test started just before the hour" do
      with_mock Rate.Private, datetime_now: clock_from(~U[2026-01-01 10:59:59.880Z]) do
        Rate.TestHelper.wait_out_window_end(3600)

        for _ <- 1..10, do: assert(AuthCodeLimits.allow_request?("a@example.com", @remote_ip))
        refute AuthCodeLimits.allow_request?("a@example.com", @remote_ip)
      end
    end
  end
end
