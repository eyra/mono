defmodule Core.AppSignal.TelemetryHandlerTest do
  use Core.DataCase

  alias Core.AppSignal.TelemetryHandler

  describe "attach/0" do
    test "attaches handlers for all configured event prefixes" do
      handlers = :telemetry.list_handlers([:feldspar, :donate, :stop])
      assert Enum.any?(handlers, &(&1.id == "appsignal-telemetry-handler"))

      handlers = :telemetry.list_handlers([:feldspar, :donate, :exception])
      assert Enum.any?(handlers, &(&1.id == "appsignal-telemetry-handler"))

      handlers = :telemetry.list_handlers([:feldspar, :donate, :rate_limited])
      assert Enum.any?(handlers, &(&1.id == "appsignal-telemetry-handler"))

      handlers = :telemetry.list_handlers([:feldspar, :log, :stop])
      assert Enum.any?(handlers, &(&1.id == "appsignal-telemetry-handler"))
    end
  end

  describe "handle_event/4 :stop" do
    test "does not crash on stop event with duration" do
      TelemetryHandler.handle_event(
        [:feldspar, :donate, :stop],
        %{duration: 1_000_000, file_size_bytes: 1024},
        %{assignment_id: "123", participant: "p1"},
        nil
      )
    end

    test "does not crash on stop event without extra measurements" do
      TelemetryHandler.handle_event(
        [:feldspar, :log, :stop],
        %{duration: 500_000},
        %{level: "info", assignment_id: "456"},
        nil
      )
    end
  end

  describe "handle_event/4 :exception" do
    test "does not crash on exception event" do
      TelemetryHandler.handle_event(
        [:feldspar, :donate, :exception],
        %{duration: 2_000_000},
        %{assignment_id: "123", reason: :timeout},
        nil
      )
    end
  end

  describe "handle_event/4 :rate_limited" do
    test "does not crash on rate_limited event" do
      TelemetryHandler.handle_event(
        [:feldspar, :donate, :rate_limited],
        %{count: 1},
        %{assignment_id: "123"},
        nil
      )
    end
  end

  describe "end-to-end telemetry execute" do
    test "emitting telemetry events does not crash" do
      :telemetry.execute(
        [:feldspar, :donate, :stop],
        %{duration: 1_000_000, file_size_bytes: 2048},
        %{assignment_id: "789", participant: "p2", group: "test"}
      )

      :telemetry.execute(
        [:feldspar, :donate, :exception],
        %{duration: 500_000},
        %{assignment_id: "789", reason: :not_authenticated}
      )

      :telemetry.execute(
        [:feldspar, :donate, :rate_limited],
        %{count: 1},
        %{assignment_id: "789"}
      )

      :telemetry.execute(
        [:feldspar, :log, :stop],
        %{duration: 100_000},
        %{level: "error", assignment_id: "789"}
      )
    end

    test "handles nil metadata values without crash" do
      :telemetry.execute(
        [:feldspar, :donate, :stop],
        %{duration: 1_000_000},
        %{assignment_id: nil, participant: nil, group: nil}
      )
    end
  end
end
