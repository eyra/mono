defmodule Systems.Manual.SwitchTest do
  use Core.DataCase
  import Frameworks.Signal.TestHelper

  alias Systems.Manual
  alias Systems.Userflow
  alias Systems.Manual.Switch

  describe "manual_tool events" do
    setup do
      isolate_signals(except: [Systems.Manual.Switch])

      userflow = Repo.insert!(%Userflow.Model{})
      manual = Repo.insert!(%Manual.Model{userflow_id: userflow.id})
      tool = Repo.insert!(%Manual.ToolModel{manual_id: manual.id})
      tool = Repo.preload(tool, [:manual])

      %{manual: manual, tool: tool}
    end

    test "updates ToolView when signal has from_pid", %{tool: tool} do
      message = %{manual_tool: tool, from_pid: self()}
      assert :ok = Switch.intercept({:manual_tool, :updated}, message)

      message = assert_signal_dispatched({:embedded_live_view, Manual.ToolView})
      assert message.id == tool.id
      assert message.model.id == tool.id
      assert message.from_pid == self()
    end

    test "handles manual_tool event without from_pid", %{tool: tool} do
      message = %{manual_tool: tool}
      assert :ok = Switch.intercept({:manual_tool, :updated}, message)
      refute_signal_dispatched({:embedded_live_view, Manual.ToolView})
    end
  end

  describe "manual events" do
    setup do
      isolate_signals(except: [Systems.Manual.Switch])

      userflow = Repo.insert!(%Userflow.Model{})
      manual = Repo.insert!(%Manual.Model{userflow_id: userflow.id})
      _tool = Repo.insert!(%Manual.ToolModel{manual_id: manual.id})

      %{manual: manual}
    end

    test "dispatches manual_tool signal when manual has tool", %{manual: manual} do
      message = %{manual: manual, from_pid: self()}
      assert :ok = Switch.intercept({:manual, :updated}, message)

      # Should dispatch manual_tool signal
      assert_signal_dispatched({:manual_tool, {:manual, :updated}})
    end

    test "updates pages when signal has from_pid", %{manual: manual} do
      message = %{manual: manual, from_pid: self()}
      assert :ok = Switch.intercept({:manual, :updated}, message)

      # Should dispatch page update
      assert_signal_dispatched({:page, Manual.Builder.PublicPage})
    end
  end
end
