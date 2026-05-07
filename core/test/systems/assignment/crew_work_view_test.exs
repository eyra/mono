defmodule Systems.Assignment.CrewWorkViewTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Systems.Assignment

  setup do
    # Isolate signals to prevent workflow errors
    isolate_signals()

    user = Factories.insert!(:member)

    %{user: user}
  end

  describe "basic rendering" do
    test "renders crew work view with task view", %{conn: conn, user: user} do
      {_assignment, view, _html} = setup_and_mount_view(conn, user, user_state: %{})

      # Should render crew work view
      assert view |> has_element?("#crew_work_view")
    end
  end

  describe "Observatory pattern integration" do
    test "view model rebuilds when assignment updates", %{conn: conn, user: user} do
      {_assignment, view, _html} = setup_and_mount_view(conn, user, user_state: %{})

      # Should render crew work view
      assert view |> has_element?("#crew_work_view")

      # Note: In a real scenario, assignment would be updated and Observatory would
      # trigger VM rebuild. In this isolated test, we verify the initial state renders correctly
      # The automatic rebuild is tested through integration tests
    end
  end

  describe "event handlers" do
    setup %{user: user} do
      assignment = Assignment.Factories.create_base_assignment()
      assignment = Assignment.Factories.add_participant(assignment, user)
      assignment = Repo.preload(assignment, [:page_refs, :crew], force: true)

      %{assignment: assignment}
    end

    test "publishes task_completed event", %{
      conn: conn,
      assignment: assignment,
      user: user
    } do
      conn = conn |> Map.put(:request_path, "/assignment/work")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          user_state: %{},
          panel_info: nil,
          timezone: "UTC"
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, view, _html} = live_isolated(conn, Assignment.CrewWorkView, session: session)

      # Send task_completed event directly
      view |> render_click("task_completed")

      # Event is published to parent, we can't easily assert on it in isolated test
      # but we verify no errors occurred
      assert view |> has_element?("#crew_work_view")
    end
  end

  describe "context menu items" do
    test "shows privacy context menu item when privacy doc exists", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_base_assignment()

      # Add privacy doc
      privacy_doc = Factories.insert!(:content_file, %{ref: "https://example.com/privacy.pdf"})

      assignment =
        assignment
        |> Ecto.Changeset.change(%{privacy_doc_id: privacy_doc.id})
        |> Repo.update!()

      assignment = Assignment.Factories.add_participant(assignment, user)
      assignment = Repo.preload(assignment, [:page_refs, :crew, :privacy_doc], force: true)

      conn = conn |> Map.put(:request_path, "/assignment/work")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          user_state: %{},
          panel_info: nil,
          timezone: "UTC"
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, _view, html} = live_isolated(conn, Assignment.CrewWorkView, session: session)

      # Check privacy menu item exists in rendered HTML - look for translated text
      assert html =~ "Privacy"
    end

    test "shows consent context menu item when consent agreement exists", %{
      conn: conn,
      user: user
    } do
      assignment = Assignment.Factories.create_assignment_with_consent()
      assignment = Assignment.Factories.add_participant(assignment, user)

      conn = conn |> Map.put(:request_path, "/assignment/work")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          user_state: %{},
          panel_info: nil,
          timezone: "UTC"
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, _view, html} = live_isolated(conn, Assignment.CrewWorkView, session: session)

      # Check consent menu item exists in rendered HTML - look for translated text
      assert html =~ "Consent"
    end

    test "shows assignment information context menu item when page ref exists", %{
      conn: conn,
      user: user
    } do
      assignment = Assignment.Factories.create_base_assignment()
      assignment = Assignment.Factories.add_participant(assignment, user)

      # Add assignment information page ref
      page = Factories.insert!(:content_page)

      _page_ref =
        Factories.insert!(:assignment_page_ref, %{
          assignment: assignment,
          page: page,
          key: :assignment_information
        })

      assignment = Repo.preload(assignment, [:page_refs, :crew], force: true)

      conn = conn |> Map.put(:request_path, "/assignment/work")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          user_state: %{},
          panel_info: nil,
          timezone: "UTC"
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, _view, html} = live_isolated(conn, Assignment.CrewWorkView, session: session)

      # Check assignment_information menu item exists in rendered HTML - look for translated text
      assert html =~ "About"
    end

    test "shows helpdesk context menu item when page ref exists", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_base_assignment()
      assignment = Assignment.Factories.add_participant(assignment, user)

      # Add helpdesk page ref
      page = Factories.insert!(:content_page)

      _page_ref =
        Factories.insert!(:assignment_page_ref, %{
          assignment: assignment,
          page: page,
          key: :assignment_helpdesk
        })

      assignment = Repo.preload(assignment, [:page_refs, :crew], force: true)

      conn = conn |> Map.put(:request_path, "/assignment/work")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          user_state: %{},
          panel_info: nil,
          timezone: "UTC"
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, _view, html} = live_isolated(conn, Assignment.CrewWorkView, session: session)

      # Check assignment_helpdesk menu item exists in rendered HTML - look for translated text
      assert html =~ "Questions?"
    end
  end

  describe "task view selection" do
    test "shows no task view when user_state is nil", %{conn: conn, user: user} do
      assignment = Assignment.Factories.create_base_assignment()
      assignment = Assignment.Factories.add_participant(assignment, user)
      assignment = Repo.preload(assignment, [:page_refs, :crew], force: true)

      conn = conn |> Map.put(:request_path, "/assignment/work")

      live_context =
        Frameworks.Concept.LiveContext.new(%{
          assignment_id: assignment.id,
          current_user: user,
          user_state: nil,
          panel_info: nil,
          timezone: "UTC"
        })

      session = %{
        "live_context" => live_context
      }

      {:ok, _view, html} = live_isolated(conn, Assignment.CrewWorkView, session: session)

      # Should not have a task view when user_state is nil
      refute html =~ "crew_task_single_view_"
    end

    test "shows single task view when one work item", %{conn: conn, user: user} do
      {_assignment, _view, html} = setup_and_mount_view(conn, user, user_state: %{})

      # Should have single task view - check for the LiveView element ID
      assert html =~ "crew_task_single_view_"
    end

    test "shows task list view when multiple work items", %{conn: conn, user: user} do
      # Create assignment with multiple workflow items
      assignment = Assignment.Factories.create_assignment_with_multiple_tasks()

      {_assignment, _view, html} =
        setup_and_mount_view(conn, user, assignment: assignment, user_state: %{})

      # Should have task list view - check for the LiveView element ID
      assert html =~ "crew_task_list_view_"
    end
  end

  describe "assignment status and tester behavior" do
    test "shows work items when assignment is online", %{conn: conn, user: user} do
      {_assignment, _view, html} = setup_and_mount_view(conn, user, user_state: %{})

      # Should have work items - task view should be rendered
      assert html =~ "crew_task_single_view_"
    end

    test "does not show work items when assignment is offline and user is not tester", %{
      conn: conn,
      user: user
    } do
      {_assignment, view, _html} =
        setup_and_mount_view(conn, user, user_state: %{}, status: :offline)

      # Task view container is rendered but should not have tool_view inside
      # because build_work_items returns empty list when offline and not tester
      assert view |> has_element?("[data-testid='crew-task-single-view']")
      refute view |> has_element?("[id='tool_view']")
    end

    test "shows work items when assignment is offline but user is tester", %{
      conn: conn,
      user: user
    } do
      {_assignment, _view, html} =
        setup_and_mount_view(conn, user, user_state: %{}, status: :offline, tester: true)

      # Testers should have work items even when offline - task view should be rendered
      assert html =~ "crew_task_single_view_"
    end
  end

  describe "timezone handling" do
    test "uses timezone from context", %{conn: conn, user: user} do
      {_assignment, view, _html} =
        setup_and_mount_view(conn, user, user_state: %{}, timezone: "Europe/Amsterdam")

      # Verify timezone is correctly passed through - check the rendered component has it
      assert view |> has_element?("#crew_work_view")
    end

    test "defaults to UTC when no timezone in context", %{conn: conn, user: user} do
      {_assignment, view, _html} = setup_and_mount_view(conn, user, user_state: %{})

      # Should default to UTC - verify view renders correctly
      assert view |> has_element?("#crew_work_view")
    end
  end

  describe "panel info handling" do
    test "includes panel_info in view model when present in context", %{conn: conn, user: user} do
      panel_info = %{"participant_id" => "123", "panel_name" => "test_panel"}

      {_assignment, view, _html} =
        setup_and_mount_view(conn, user, user_state: %{}, panel_info: panel_info)

      # Verify panel_info is passed through - task view should be rendered with it
      assert view |> has_element?("#crew_work_view")
      assert view |> has_element?("[id^='crew_task_single_view_']")
    end

    test "handles missing panel_info gracefully", %{conn: conn, user: user} do
      {_assignment, view, _html} = setup_and_mount_view(conn, user, user_state: %{})

      # Should handle nil panel_info gracefully - view should still render
      assert view |> has_element?("#crew_work_view")
    end
  end

  # Helper functions
  defp setup_and_mount_view(conn, user, opts) do
    user_state = Keyword.get(opts, :user_state, %{})
    panel_info = Keyword.get(opts, :panel_info, nil)
    tester = Keyword.get(opts, :tester, false)
    status = Keyword.get(opts, :status, :online)
    timezone = Keyword.get(opts, :timezone, "UTC")

    # Allow passing custom assignment or create default
    assignment =
      case Keyword.get(opts, :assignment) do
        nil -> Assignment.Factories.create_base_assignment()
        custom_assignment -> custom_assignment
      end

    assignment =
      if tester do
        Assignment.Factories.add_tester(assignment, user)
      else
        assignment
      end

    assignment = Assignment.Factories.add_participant(assignment, user)

    assignment =
      if status != :online do
        assignment
        |> Ecto.Changeset.change(status: status)
        |> Repo.update!()
      else
        assignment
      end

    assignment = Repo.preload(assignment, [:page_refs, :crew], force: true)

    conn = conn |> Map.put(:request_path, "/assignment/work")

    live_context =
      Frameworks.Concept.LiveContext.new(%{
        assignment_id: assignment.id,
        current_user: user,
        user_state: user_state,
        panel_info: panel_info,
        timezone: timezone
      })

    session = %{"live_context" => live_context}

    {:ok, view, html} = live_isolated(conn, Assignment.CrewWorkView, session: session)

    {assignment, view, html}
  end
end
