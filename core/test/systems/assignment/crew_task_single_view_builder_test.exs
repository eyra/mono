defmodule Systems.Assignment.CrewTaskSingleViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Core.Repo
  alias Systems.Assignment

  describe "view_model/2" do
    setup do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_base_assignment()
      assignment = Assignment.Factories.add_participant(assignment, user)
      assignment = Repo.preload(assignment, Assignment.Model.preload_graph(:down), force: true)

      %{user: user, assignment: assignment}
    end

    test "builds correct VM with tool_view", %{
      user: user,
      assignment: assignment
    } do
      live_context =
        Frameworks.Concept.LiveContext.new(%{
          current_user: user
        })

      assigns = %{
        current_user: user,
        live_context: live_context
      }

      vm = Assignment.CrewTaskSingleViewBuilder.view_model(assignment, assigns)

      # Should have work_item
      assert vm.work_item != nil
      {workflow_item, task} = vm.work_item
      assert workflow_item.title == "Test Task"
      assert task.identifier != nil

      # Should have tool_view configured correctly
      assert vm.tool_view != nil
      assert vm.tool_view.id == "tool_view"
      assert vm.tool_view.type == :live_view
      assert vm.tool_view.implementation == Systems.Alliance.ToolView
    end

    test "extends parent_context with workflow item data", %{
      user: user,
      assignment: assignment
    } do
      live_context =
        Frameworks.Concept.LiveContext.new(%{
          current_user: user
        })

      assigns = %{
        current_user: user,
        live_context: live_context
      }

      vm = Assignment.CrewTaskSingleViewBuilder.view_model(assignment, assigns)

      # Get the workflow item from work_item
      {workflow_item, _task} = vm.work_item

      # Extended context should have workflow_item_id, title, and icon
      task_context = vm.tool_view.options[:live_context]
      assert task_context.data.workflow_item_id == workflow_item.id
      assert task_context.data.title == workflow_item.title
      assert task_context.data.presentation == :embedded

      # Parent context data should still be present
      assert task_context.data.current_user == user
    end

    test "returns nil tool_view when no work items", %{user: user} do
      # Create assignment without adding user as participant
      assignment = Assignment.Factories.create_base_assignment()

      # User is not a participant, so build_work_items returns []
      live_context =
        Frameworks.Concept.LiveContext.new(%{
          current_user: user
        })

      assigns = %{
        current_user: user,
        live_context: live_context
      }

      vm = Assignment.CrewTaskSingleViewBuilder.view_model(assignment, assigns)

      # Should have nil work_item and tool_view
      assert vm.work_item == nil
      assert vm.tool_view == nil
    end
  end
end
