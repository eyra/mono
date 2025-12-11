defmodule Systems.Assignment.CrewTaskListViewBuilderTest do
  use Core.DataCase
  use Gettext, backend: CoreWeb.Gettext

  alias Core.Repo
  alias Systems.Assignment

  describe "view_model/2" do
    setup do
      user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_assignment_with_multiple_tasks()
      assignment = Assignment.Factories.add_participant(assignment, user)
      assignment = Repo.preload(assignment, Assignment.Model.preload_graph(:down), force: true)

      %{user: user, assignment: assignment}
    end

    test "builds correct VM with work items", %{user: user, assignment: assignment} do
      assigns = build_assigns(user, %{task: nil})

      vm = Assignment.CrewTaskListViewBuilder.view_model(assignment, assigns)

      # Should have title
      assert vm.title == dgettext("eyra-assignment", "work.list.title")

      # Should have work_items
      assert length(vm.work_items) == 2

      # Should have work_list with items
      assert length(vm.work_list.items) == 2
      assert vm.work_list.selected_item_id == nil

      # Should have work_item_id (nil if no selection)
      assert vm.work_item_id == nil

      # Should have tool_modal (nil if no selection)
      assert vm.tool_modal == nil
    end

    test "handles user_state with task selection", %{user: user, assignment: assignment} do
      # Get first workflow item id
      [first_item | _] = Systems.Workflow.Model.ordered_items(assignment.workflow)
      work_item_id = first_item.id

      assigns = build_assigns(user, %{task: work_item_id})

      vm = Assignment.CrewTaskListViewBuilder.view_model(assignment, assigns)

      # Should have work_item_id from user_state
      assert vm.work_item_id == work_item_id

      # Should have tool_modal since a work item is selected
      assert vm.tool_modal != nil
    end

    test "handles empty work items when user not participant", %{user: _user} do
      # Create a new user who is not a participant
      other_user = Factories.insert!(:member)
      assignment = Assignment.Factories.create_assignment_with_multiple_tasks()
      assignment = Repo.preload(assignment, Assignment.Model.preload_graph(:down), force: true)

      assigns = build_assigns(other_user, %{task: nil})

      vm = Assignment.CrewTaskListViewBuilder.view_model(assignment, assigns)

      # Should handle empty work items gracefully (user not a member)
      assert vm.work_items == []
      assert vm.work_list.items == []
      assert vm.work_item_id == nil
      assert vm.tool_modal == nil
    end
  end

  # Helper functions
  defp build_assigns(user, user_state) do
    live_context =
      Frameworks.Concept.LiveContext.new(%{
        current_user: user,
        timezone: "UTC",
        user_state: user_state,
        panel_info: nil
      })

    %{
      current_user: user,
      user_state: user_state,
      live_context: live_context
    }
  end
end
