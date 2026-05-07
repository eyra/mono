defmodule Systems.Graphite.SwitchTest do
  use Core.DataCase
  import Frameworks.Signal.TestHelper

  alias Systems.Graphite
  alias Systems.Graphite.Switch

  describe "graphite_tool events" do
    setup do
      isolate_signals(except: [Systems.Graphite.Switch])

      tool = Factories.insert!(:graphite_tool)
      %{tool: tool}
    end

    test "updates ToolView when signal has from_pid", %{tool: tool} do
      message = %{graphite_tool: tool, from_pid: self()}
      assert :ok = Switch.intercept({:graphite_tool, :updated}, message)

      message = assert_signal_dispatched({:embedded_live_view, Graphite.ToolView})
      assert message.id == tool.id
      assert message.model.id == tool.id
      assert message.from_pid == self()
    end

    test "handles graphite_tool event without from_pid", %{tool: tool} do
      message = %{graphite_tool: tool}
      assert :ok = Switch.intercept({:graphite_tool, :updated}, message)
      refute_signal_dispatched({:embedded_live_view, Graphite.ToolView})
    end

    test "dispatches leaderboard signal when tool has leaderboard", %{tool: tool} do
      # Create leaderboard with the tool
      _leaderboard = Factories.insert!(:graphite_leaderboard, %{tool: tool})

      message = %{graphite_tool: tool, from_pid: self()}
      assert :ok = Switch.intercept({:graphite_tool, :updated}, message)

      # Should dispatch leaderboard signal
      assert_signal_dispatched({:graphite_leaderboard, {:graphite_tool, :updated}})
    end
  end

  describe "graphite_leaderboard events" do
    setup do
      isolate_signals(except: [Systems.Graphite.Switch])

      tool = Factories.insert!(:graphite_tool)
      leaderboard = Factories.insert!(:graphite_leaderboard, %{tool: tool})
      %{tool: tool, leaderboard: leaderboard}
    end

    test "updates pages when signal has from_pid", %{leaderboard: leaderboard} do
      message = %{graphite_leaderboard: leaderboard, from_pid: self()}
      assert :ok = Switch.intercept({:graphite_leaderboard, :updated}, message)

      # Should dispatch page updates
      assert_signal_dispatched({:page, Graphite.LeaderboardPage})
      assert_signal_dispatched({:page, Graphite.LeaderboardContentPage})
    end
  end
end
