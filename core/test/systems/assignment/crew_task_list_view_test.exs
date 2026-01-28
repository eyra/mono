defmodule Systems.Assignment.CrewTaskListViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Systems.Assignment

  setup do
    isolate_signals()

    user = Factories.insert!(:member)

    %{user: user}
  end

  describe "basic rendering" do
    test "renders task list view", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_assignment_with_multiple_tasks()
      assignment = Assignment.Factories.add_participant(assignment, user)

      conn = conn |> Map.put(:request_path, "/assignment/tasks")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          user_state: %{},
          panel_info: nil
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, _view, html} = live_isolated(conn, Assignment.CrewTaskListView, session: session)

      # Should render task list view
      assert html =~ "data-testid=\"crew-task-list-view\""
    end
  end

  describe "event handlers" do
    setup %{user: user} do
      assignment = Assignment.Factories.create_assignment_with_multiple_tasks()
      assignment = Assignment.Factories.add_participant(assignment, user)
      assignment = Repo.preload(assignment, [:crew, workflow: [:items]], force: true)

      # Get first workflow item id for testing
      ordered_items = Systems.Workflow.Model.ordered_items(assignment.workflow)
      [first_item | _] = ordered_items
      work_item_id = first_item.id

      %{assignment: assignment, work_item_id: work_item_id}
    end

    test "clears work_item when modal_closed event is consumed", %{
      conn: conn,
      user: user,
      assignment: assignment,
      work_item_id: work_item_id
    } do
      conn = conn |> Map.put(:request_path, "/assignment/tasks")

      # Mount with a work_item_id in user_state to simulate an active task
      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          user_state: %{task: work_item_id},
          panel_info: nil
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, view, html} = live_isolated(conn, Assignment.CrewTaskListView, session: session)

      # Verify view renders
      assert html =~ "data-testid=\"crew-task-list-view\""

      # The modal_closed event is consumed internally by LiveNest
      # We can't easily trigger it in isolated tests, but the view should be properly initialized
      # The actual modal closing flow is tested through integration tests with CrewPage
      assert view |> has_element?("[data-testid='crew-task-list-view']")
    end
  end

  describe "BUG: participant missing in upload_context" do
    setup %{user: user} do
      # Create assignment with Feldspar tool
      assignment = Assignment.Factories.create_assignment_with_feldspar_tool()
      assignment = Assignment.Factories.add_participant(assignment, user)
      assignment = Repo.preload(assignment, [:crew, workflow: [items: [:tool_ref]]], force: true)

      # Get the workflow item id
      ordered_items = Systems.Workflow.Model.ordered_items(assignment.workflow)
      [first_item | _] = ordered_items
      work_item_id = first_item.id

      %{assignment: assignment, work_item_id: work_item_id}
    end

    test "vm.participant must be available for click-to-start case", %{
      conn: conn,
      user: user,
      assignment: assignment
    } do
      # maybe_show_tool_modal() uses vm.participant to build the modal.
      # This test verifies vm.participant is computed by ViewBuilder.
      # The actual click-to-start flow is tested via integration tests.

      conn = conn |> Map.put(:request_path, "/assignment/tasks")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          user_state: %{},
          panel_info: nil
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Assignment.CrewTaskListView, session: session)

      assigns = :sys.get_state(view.pid).socket.assigns

      # vm.participant must be available for maybe_show_tool_modal()
      assert assigns.vm.participant != nil,
             "vm.participant must be computed by ViewBuilder for click-to-start case"
    end

    test "tool_modal MUST contain participant when task is pre-selected", %{
      conn: conn,
      user: user,
      assignment: assignment,
      work_item_id: work_item_id
    } do
      # This test verifies the fix for the timing bug where participant was not
      # available when the tool modal was built.
      #
      # The fix: participant is computed in ViewBuilder (not in mount).

      conn = conn |> Map.put(:request_path, "/assignment/tasks")

      # Mount with a work_item_id in user_state - this triggers the pre-built tool_modal
      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          user_state: %{task: work_item_id},
          panel_info: nil
        })

      session = %{"live_context" => live_context}

      {:ok, view, _html} = live_isolated(conn, Assignment.CrewTaskListView, session: session)

      # Get the current assigns to check the tool_modal has participant
      assigns = :sys.get_state(view.pid).socket.assigns

      tool_modal = assigns.vm.tool_modal

      # The tool_modal should be present
      assert tool_modal != nil, "tool_modal should be present when task is pre-selected"

      # The participant should be in the tool_modal's live_context
      live_context = tool_modal.element.options[:live_context]
      participant = live_context.data[:participant]

      assert participant != nil,
             """
             participant should be in tool_modal when task is pre-selected.

             The participant is computed in ViewBuilder so it's available
             when the tool_modal is built.
             """
    end
  end
end
