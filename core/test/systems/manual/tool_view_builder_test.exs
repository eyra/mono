defmodule Systems.Manual.ToolViewBuilderTest do
  use Core.DataCase

  alias Frameworks.Concept.LiveContext
  alias Systems.Manual

  describe "view_model/2" do
    setup do
      user = Factories.insert!(:member)

      # Create userflow, manual and tool
      userflow = Repo.insert!(%Systems.Userflow.Model{})
      manual = Repo.insert!(%Manual.Model{userflow_id: userflow.id})
      tool = Repo.insert!(%Manual.ToolModel{manual_id: manual.id})
      tool = Repo.preload(tool, [:manual])

      %{user: user, tool: tool, manual: manual}
    end

    test "builds correct VM with all required fields", %{user: user, tool: tool, manual: manual} do
      # Context with user_state data for this manual
      context =
        LiveContext.new(%{
          current_user: user,
          user_state: %{chapter: 2, section: 1},
          title: "Test Manual"
        })

      assigns = %{live_context: context, title: "Test Manual"}

      vm = Manual.ToolViewBuilder.view_model(tool, assigns)

      # Should have tool and title
      assert vm.manual.id == tool.id
      assert vm.title == "Test Manual"

      # Should have manual_view configured as LiveNest element
      assert %LiveNest.Element{} = vm.manual_view
      assert vm.manual_view.implementation == Manual.View
      assert vm.manual_view.id == "manual_view"

      # Options should contain live_context with manual_id
      [element_id: _, live_context: session_context] = vm.manual_view.options
      assert session_context.data.manual_id == manual.id
      assert session_context.data.current_user == user
      assert session_context.data.user_state == %{chapter: 2, section: 1}
    end

    test "handles empty user_state", %{user: user, tool: tool, manual: manual} do
      context =
        LiveContext.new(%{
          current_user: user,
          user_state: %{},
          title: "Test Manual"
        })

      assigns = %{live_context: context, title: "Test Manual"}

      vm = Manual.ToolViewBuilder.view_model(tool, assigns)

      # Options should contain context with empty user_state
      [element_id: _, live_context: session_context] = vm.manual_view.options
      assert session_context.data.manual_id == manual.id
      assert session_context.data.user_state == %{}
    end

    test "preserves embedded presentation from parent context", %{user: user, tool: tool} do
      # Context with embedded presentation (as set by CrewTaskSingleViewBuilder)
      context =
        LiveContext.new(%{
          current_user: user,
          user_state: %{},
          title: "Test Manual",
          presentation: :embedded
        })

      assigns = %{live_context: context, title: "Test Manual"}

      vm = Manual.ToolViewBuilder.view_model(tool, assigns)

      # Should preserve embedded presentation
      [element_id: _, live_context: session_context] = vm.manual_view.options
      assert session_context.data.presentation == :embedded
    end

    test "defaults to modal presentation when not specified", %{user: user, tool: tool} do
      # Context without presentation (legacy case)
      context =
        LiveContext.new(%{
          current_user: user,
          user_state: %{},
          title: "Test Manual"
        })

      assigns = %{live_context: context, title: "Test Manual"}

      vm = Manual.ToolViewBuilder.view_model(tool, assigns)

      # Should default to modal presentation
      [element_id: _, live_context: session_context] = vm.manual_view.options
      assert session_context.data.presentation == :modal
    end
  end
end
