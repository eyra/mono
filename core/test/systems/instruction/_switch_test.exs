defmodule Systems.Instruction.SwitchTest do
  use Core.DataCase
  import Frameworks.Signal.TestHelper

  alias Systems.Instruction
  alias Systems.Instruction.Switch

  describe "instruction_tool events" do
    setup do
      isolate_signals(except: [Systems.Instruction.Switch])

      auth_node = Factories.insert!(:auth_node)
      tool = Repo.insert!(%Instruction.ToolModel{auth_node_id: auth_node.id})

      %{tool: tool}
    end

    test "updates ToolView when signal has from_pid", %{tool: tool} do
      message = %{instruction_tool: tool, from_pid: self()}
      assert :ok = Switch.intercept({:instruction_tool, :updated}, message)

      message = assert_signal_dispatched({:embedded_live_view, Instruction.ToolView})
      assert message.id == tool.id
      assert message.model.id == tool.id
      assert message.from_pid == self()
    end

    test "handles instruction_tool event without from_pid", %{tool: tool} do
      message = %{instruction_tool: tool}
      assert :ok = Switch.intercept({:instruction_tool, :updated}, message)
      refute_signal_dispatched({:embedded_live_view, Instruction.ToolView})
    end

    test "handles any instruction_tool event", %{tool: tool} do
      events = [:updated, :created, :deleted]

      for event <- events do
        message = %{instruction_tool: tool, from_pid: self()}
        assert :ok = Switch.intercept({:instruction_tool, event}, message)
      end
    end
  end

  describe "instruction_asset events" do
    setup do
      isolate_signals(except: [Systems.Instruction.Switch])

      auth_node = Factories.insert!(:auth_node)
      tool = Repo.insert!(%Instruction.ToolModel{auth_node_id: auth_node.id})

      asset =
        Repo.insert!(%Instruction.AssetModel{
          tool_id: tool.id
        })

      %{tool: tool, asset: asset}
    end

    test "dispatches instruction_tool signal", %{tool: tool, asset: asset} do
      message = %{instruction_asset: asset, from_pid: self()}
      assert :ok = Switch.intercept({:instruction_asset, :updated}, message)

      # Should dispatch instruction_tool signal
      message = assert_signal_dispatched({:instruction_tool, {:instruction_asset, :updated}})
      assert message.instruction_tool.id == tool.id
    end
  end

  describe "content_page events" do
    setup do
      isolate_signals(except: [Systems.Instruction.Switch])

      auth_node = Factories.insert!(:auth_node)
      tool = Repo.insert!(%Instruction.ToolModel{auth_node_id: auth_node.id})
      content_page = Factories.insert!(:content_page)

      # Create instruction page reference
      _instruction_page =
        Repo.insert!(%Instruction.PageModel{
          tool_id: tool.id,
          page_id: content_page.id
        })

      %{tool: tool, content_page: content_page}
    end

    test "dispatches instruction_tool signal when content_page has tool", %{
      content_page: content_page
    } do
      message = %{content_page: content_page, from_pid: self()}
      assert :ok = Switch.intercept({:content_page, :updated}, message)

      # Should dispatch instruction_tool signal
      assert_signal_dispatched({:instruction_tool, {:content_page, :updated}})
    end
  end
end
