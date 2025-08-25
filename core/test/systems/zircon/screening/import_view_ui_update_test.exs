defmodule Systems.Zircon.Screening.ImportViewUIUpdateTest do
  use CoreWeb.ConnCase, async: false
  use Oban.Testing, repo: Core.Repo
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Systems.Paper
  alias Systems.Zircon
  alias Systems.Zircon.Screening

  setup do
    # Isolate signals to prevent workflow errors, but keep Observatory.Switch for UI updates
    isolate_signals(except: [Systems.Zircon.Switch, Systems.Observatory.Switch])

    # Create required entities
    auth_node = Factories.insert!(:auth_node)
    tool = Factories.insert!(:zircon_screening_tool, %{auth_node: auth_node})

    # Create paper set
    paper_set = Paper.Public.obtain_paper_set!(:zircon_screening_tool, tool.id)

    # Create reference file
    reference_file =
      Zircon.Public.insert_reference_file!(tool, "test.ris", "http://example.com/test.ris")

    %{tool: tool, paper_set: paper_set, reference_file: reference_file}
  end

  describe "UI updates immediately when clicking Continue" do
    test "shows importing message with spinner for large imports (20+ items)", %{
      conn: conn,
      tool: tool,
      paper_set: paper_set,
      reference_file: reference_file
    } do
      # Create an import session in prompting phase with 20+ papers to meet threshold
      entries =
        Enum.map(1..20, fn i ->
          %{
            "title" => "Test Paper #{i}",
            "authors" => ["Test Author #{i}"],
            "year" => "2024",
            "doi" => "10.1234/test#{i}",
            "status" => "new",
            "processed_attrs" => %{
              "title" => "Test Paper #{i}",
              "authors" => ["Test Author #{i}"],
              "year" => "2024",
              "doi" => "10.1234/test#{i}"
            }
          }
        end)

      import_session =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: entries,
          errors: [],
          summary: %{
            "total" => 20,
            "predicted_new" => 20,
            "predicted_existing" => 0
          }
        })

      conn = conn |> Map.put(:request_path, "/zircon/screening/import")

      session_data = %{
        "title" => "UI Update Test",
        "tool" => tool
      }

      {:ok, view, initial_html} = live_isolated(conn, Screening.ImportView, session: session_data)

      # Verify initial state - prompting summary with Continue button
      assert initial_html =~ "prompting-summary-block"

      assert view |> has_element?("[phx-click='commit_import']"),
             "Continue button should be visible initially"

      # Mock the import to take some time so we can check the intermediate state
      # We'll use Mox to mock Paper.RISEntry.from_map to add a delay

      # Click the Continue button

      view |> element("[phx-click='commit_import']") |> render_click()

      # IMMEDIATELY check the UI - should show importing state
      # Don't wait for completion, check right after the click
      intermediate_html = render(view)

      # CRITICAL ASSERTIONS FOR INTERMEDIATE STATE:

      # 1. Should show processing status block with importing message
      assert intermediate_html =~ "processing-status-block",
             "Processing status block should be shown immediately"

      # 2. Should show "Importing papers..." message
      assert intermediate_html =~ "Importing papers",
             "Should show 'Importing papers...' message"

      # 3. Should show spinner
      assert intermediate_html =~ "Spinner" || intermediate_html =~ "spinner",
             "Spinner should be visible during import"

      # 4. Should NOT show Continue button anymore
      refute view |> has_element?("[phx-click='commit_import']"),
             "Continue button should be hidden during import"

      # 5. File selector should STILL be visible as an escape route
      assert intermediate_html =~ "file-selector",
             "File selector should remain visible during import as an escape route"

      # 6. Should NOT show prompting summary anymore
      refute intermediate_html =~ "prompting-summary-block",
             "Prompting summary should be replaced by processing status"

      # 7. Should NOT show any action buttons
      refute intermediate_html =~ "phx-click=\"abort\"",
             "No abort button should be visible during import"

      # Now manually run the Oban job to complete the import
      # In test mode, Oban queues are disabled so we need to manually perform the job
      assert :ok =
               Paper.RISImportCommitJob.perform(%Oban.Job{
                 args: %{"session_id" => import_session.id}
               })

      # Give the UI a moment to update after job completion
      Process.sleep(100)

      # After completion, verify final state
      final_html = render(view)

      # Session should be completed
      final_session = Core.Repo.get!(Paper.RISImportSessionModel, import_session.id)
      assert final_session.status == :succeeded

      # UI should show file selector again for new imports
      assert final_html =~ "file-selector",
             "File selector should be available after import completes"

      # No processing status should be shown after completion
      refute final_html =~ "processing-status-block",
             "Processing status should be removed after completion"
    end

    test "small imports complete without showing progress UI", %{
      conn: conn,
      tool: tool,
      paper_set: paper_set,
      reference_file: reference_file
    } do
      # This test verifies that small imports (< threshold) complete without showing progress UI
      # The UI should transition from prompting directly to completion without intermediate progress

      # Create session in prompting phase with only 1 paper (below threshold)
      import_session =
        Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [
            %{
              "title" => "Single Test Paper",
              "status" => "new",
              "processed_attrs" => %{"title" => "Single Test Paper"}
            }
          ]
        })

      conn = conn |> Map.put(:request_path, "/zircon/screening/import")

      {:ok, view, _} =
        live_isolated(conn, Screening.ImportView,
          session: %{"title" => "Phase Test", "tool" => tool}
        )

      # Phase 1: Prompting - should show Continue button
      prompting_html = render(view)
      assert prompting_html =~ "Add new papers"
      assert view |> has_element?("[phx-click='commit_import']")

      # Click Continue to trigger import
      view |> element("[phx-click='commit_import']") |> render_click()

      # For small imports (below threshold), NO progress UI should show
      # The import should complete quickly without intermediate UI
      importing_html = render(view)

      # Should NOT show progress UI for small operations
      refute importing_html =~ "processing-status-block",
             "Small imports should not show progress UI (threshold behavior)"

      # The import continues but without visible progress indicators

      refute view |> has_element?("[phx-click='commit_import']"),
             "Continue button should be removed during import"

      # Phase 3: Manually run the job to complete the import
      # In test mode, Oban queues are disabled so we need to manually perform the job
      assert :ok =
               Paper.RISImportCommitJob.perform(%Oban.Job{
                 args: %{"session_id" => import_session.id}
               })

      # Give the UI a moment to update after job completion
      Process.sleep(100)

      completed_html = render(view)

      refute completed_html =~ "Importing papers",
             "Should not show importing message after completion"

      refute completed_html =~ "processing-status-block",
             "Should not show processing status after completion"
    end
  end
end
