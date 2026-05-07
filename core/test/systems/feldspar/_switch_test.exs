defmodule Systems.Feldspar.SwitchTest do
  use Core.DataCase
  import Frameworks.Signal.TestHelper

  alias Systems.Feldspar.Switch

  describe "feldspar_tool events" do
    setup do
      isolate_signals(except: [Systems.Feldspar.Switch])

      tool = Factories.insert!(:feldspar_tool)
      %{tool: tool}
    end

    test "updates ToolView when signal has from_pid", %{tool: tool} do
      message = %{feldspar_tool: tool, from_pid: self()}
      assert :ok = Switch.intercept({:feldspar_tool, :updated}, message)

      message = assert_signal_dispatched({:embedded_live_view, Systems.Feldspar.ToolView})
      assert message.id == tool.id
      assert message.model.id == tool.id
      assert message.from_pid == self()
    end

    test "handles any feldspar_tool event", %{tool: tool} do
      events = [:updated, :created, :deleted, :update_and_dispatch]

      for event <- events do
        message = %{feldspar_tool: tool, from_pid: self()}
        assert :ok = Switch.intercept({:feldspar_tool, event}, message)
      end
    end

    test "handles message without from_pid", %{tool: tool} do
      message = %{feldspar_tool: tool}
      assert :ok = Switch.intercept({:feldspar_tool, :updated}, message)
      refute_signal_dispatched({:embedded_live_view, Systems.Feldspar.ToolView})
    end
  end
end
