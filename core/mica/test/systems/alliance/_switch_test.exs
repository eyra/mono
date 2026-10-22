defmodule Systems.Alliance.SwitchTest do
  use Core.DataCase
  import Frameworks.Signal.TestHelper

  alias Systems.Alliance.Switch

  describe "alliance_tool events" do
    setup do
      isolate_signals(except: [Systems.Alliance.Switch])

      tool = Factories.insert!(:alliance_tool)
      %{tool: tool}
    end

    test "updates ToolView when signal has from_pid", %{tool: tool} do
      message = %{alliance_tool: tool, from_pid: self()}
      assert :ok = Switch.intercept({:alliance_tool, :updated}, message)

      message = assert_signal_dispatched({:embedded_live_view, Systems.Alliance.ToolView})
      assert message.id == tool.id
      assert message.model.id == tool.id
      assert message.from_pid == self()
    end

    test "handles any alliance_tool event", %{tool: tool} do
      events = [:updated, :created, :deleted, :update_and_dispatch]

      for event <- events do
        message = %{alliance_tool: tool, from_pid: self()}
        assert :ok = Switch.intercept({:alliance_tool, event}, message)
      end
    end

    test "handles message without from_pid", %{tool: tool} do
      message = %{alliance_tool: tool}
      assert :ok = Switch.intercept({:alliance_tool, :updated}, message)
      refute_signal_dispatched({:embedded_live_view, Systems.Alliance.ToolView})
    end
  end
end
