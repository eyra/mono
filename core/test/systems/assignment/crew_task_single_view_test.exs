defmodule Systems.Assignment.CrewTaskSingleViewTest do
  use CoreWeb.ConnCase, async: false
  use Gettext, backend: CoreWeb.Gettext
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
    test "renders task single view container", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_base_assignment()
      assignment = Assignment.Factories.add_participant(assignment, user)

      conn = conn |> Map.put(:request_path, "/assignment/task")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          panel_info: nil
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, _view, html} = live_isolated(conn, Assignment.CrewTaskSingleView, session: session)

      # Should render task single view container
      assert html =~ "data-testid=\"crew-task-single-view\""
    end
  end

  describe "event handlers" do
    setup %{user: user} do
      assignment = Assignment.Factories.create_base_assignment()
      assignment = Assignment.Factories.add_participant(assignment, user)

      %{assignment: assignment}
    end

    test "handles complete_task event", %{conn: conn, user: user, assignment: assignment} do
      conn = conn |> Map.put(:request_path, "/assignment/task")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          panel_info: nil
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, view, _html} = live_isolated(conn, Assignment.CrewTaskSingleView, session: session)

      # Send complete_task event
      html = view |> render_click("complete_task")

      # Verify view still renders after event
      assert html =~ "data-testid=\"crew-task-single-view\""
    end
  end

  describe "handle_info messages" do
    test "handles :show_flash message without crashing", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_base_assignment()
      assignment = Assignment.Factories.add_participant(assignment, user)

      conn = conn |> Map.put(:request_path, "/assignment/task")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          panel_info: nil
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, view, _html} = live_isolated(conn, Assignment.CrewTaskSingleView, session: session)

      # Send the :show_flash message that was causing FunctionClauseError
      flash_message =
        {:show_flash, %{auto_hide: false, message: "Test error message", type: :error}}

      send(view.pid, flash_message)

      # View should still be alive and functioning after receiving the message
      html = render(view)
      assert html =~ "data-testid=\"crew-task-single-view\""
    end

    test "handles :hide_flash message without crashing", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_base_assignment()
      assignment = Assignment.Factories.add_participant(assignment, user)

      conn = conn |> Map.put(:request_path, "/assignment/task")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          panel_info: nil
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, view, _html} = live_isolated(conn, Assignment.CrewTaskSingleView, session: session)

      # Send the :hide_flash message
      send(view.pid, :hide_flash)

      # View should still be alive and functioning after receiving the message
      html = render(view)
      assert html =~ "data-testid=\"crew-task-single-view\""
    end
  end

  describe "task auto-start behavior" do
    test "starts task on mount when task not started", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_base_assignment()
      assignment = Assignment.Factories.add_participant(assignment, user)
      assignment = Repo.preload(assignment, [:crew, workflow: [:items]], force: true)

      crew = assignment.crew
      member = Systems.Crew.Public.get_member(crew, user)
      ordered_items = Systems.Workflow.Model.ordered_items(assignment.workflow)
      [first_item | _] = ordered_items

      identifier = Assignment.Private.task_identifier(assignment, first_item, member)

      # Verify no task exists yet (will be created by get_or_create_task in view)
      assert is_nil(Systems.Crew.Public.get_task(crew, identifier))

      conn = conn |> Map.put(:request_path, "/assignment/task")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          panel_info: nil
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, _view, _html} = live_isolated(conn, Assignment.CrewTaskSingleView, session: session)

      # Task should now be started (created and started by mount)
      updated_task = Systems.Crew.Public.get_task(crew, identifier)
      assert not is_nil(updated_task)
      assert not is_nil(updated_task.started_at)
    end
  end
end
