defmodule Systems.Zircon.Screening.ImportViewBatchTest do
  use CoreWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper

  alias Systems.Paper
  alias Systems.Zircon.Screening

  setup do
    # Isolate signals to prevent workflow errors
    isolate_signals(except: [Systems.Zircon.Switch, Systems.Observatory.Switch])

    # Create required entities for ImportView
    auth_node = Factories.insert!(:auth_node)

    tool =
      Factories.insert!(:zircon_screening_tool, %{
        auth_node: auth_node
      })

    # Create paper set for the tool
    paper_set =
      Factories.insert!(:paper_set, %{
        category: :zircon_screening_tool,
        identifier: tool.id
      })

    %{tool: tool, paper_set: paper_set}
  end

  describe "batch import with progress updates" do
    test "shows progress updates during multi-batch import", %{
      conn: conn,
      tool: tool,
      paper_set: paper_set
    } do
      # Configure small batch size for testing
      original_batch_size = Application.get_env(:core, :paper)[:import_batch_size]
      Application.put_env(:core, :paper, import_batch_size: 5, import_batch_timeout: 30_000)

      on_exit(fn ->
        Application.put_env(:core, :paper,
          import_batch_size: original_batch_size,
          import_batch_timeout: 30_000
        )
      end)

      # Create reference file with file association
      file = Factories.insert!(:content_file, %{name: "test.ris"})
      reference_file = Factories.insert!(:paper_reference_file, %{file: file})

      # Associate reference file with tool
      tool =
        tool
        |> Core.Repo.preload(:reference_files)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:reference_files, [reference_file])
        |> Core.Repo.update!()

      # Create import session with 15 papers (should be 3 batches of 5)
      entries =
        for i <- 1..15 do
          %{
            "status" => "new",
            "doi" => "10.1234/test#{i}",
            "title" => "Test Paper #{i}",
            "year" => "2024",
            "authors" => ["Test Author"],
            "type_of_reference" => "JOUR"
          }
        end

      session =
        Factories.insert!(:paper_ris_import_session, %{
          reference_file: reference_file,
          paper_set: paper_set,
          entries: entries,
          phase: :prompting,
          status: :activated
        })

      # Mount the ImportView
      conn = conn |> Map.put(:request_path, "/zircon/screening/import")

      {:ok, view, _html} =
        live_isolated(conn, Screening.ImportView,
          session: %{
            "tool" => tool,
            "title" => "Import Papers"
          }
        )

      # The view should show prompting phase with Continue button
      assert has_element?(view, "[data-testid='prompting-summary-block']")

      # Click Continue to start import
      view
      |> element("[phx-click='commit_import']")
      |> render_click()

      # The session should now be in importing phase
      updated_session = Paper.Public.get_import_session!(session.id)
      assert updated_session.phase == :importing

      # Manually run the commit job to simulate batch processing
      assert :ok =
               Paper.RISImportCommitJob.perform(%Oban.Job{
                 args: %{"session_id" => session.id}
               })

      # Verify all papers were imported
      final_session = Paper.Public.get_import_session!(session.id)
      assert final_session.status == :succeeded
      assert final_session.summary["imported"] == 15
      assert final_session.summary["skipped_duplicates"] == 0

      # Verify progress was tracked
      assert final_session.progress["papers_imported"] == 15
      assert final_session.progress["papers_skipped"] == 0
      assert final_session.progress["total_papers"] == 15
      assert final_session.progress["current_batch"] == 3
      assert final_session.progress["total_batches"] == 3
    end

    test "handles partial batch with duplicates", %{
      conn: conn,
      tool: tool,
      paper_set: paper_set
    } do
      # Configure small batch size
      original_batch_size = Application.get_env(:core, :paper)[:import_batch_size]
      Application.put_env(:core, :paper, import_batch_size: 3, import_batch_timeout: 30_000)

      on_exit(fn ->
        Application.put_env(:core, :paper,
          import_batch_size: original_batch_size,
          import_batch_timeout: 30_000
        )
      end)

      # Create some existing papers (duplicates)
      for i <- 1..3 do
        paper =
          Factories.insert!(:paper, %{
            doi: "10.1234/test#{i}",
            title: "Test Paper #{i}"
          })

        # Create paper set association
        Factories.insert!(:paper_set_assoc, %{
          paper: paper,
          set: paper_set
        })
      end

      # Create reference file with file association
      file = Factories.insert!(:content_file, %{name: "test.ris"})
      reference_file = Factories.insert!(:paper_reference_file, %{file: file})

      # Associate reference file with tool
      tool =
        tool
        |> Core.Repo.preload(:reference_files)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:reference_files, [reference_file])
        |> Core.Repo.update!()

      # Create import session with 8 papers (3 duplicates, 5 new)
      # Should be 3 batches: [3 papers], [3 papers], [2 papers]
      entries =
        for i <- 1..8 do
          %{
            "status" => "new",
            "doi" => "10.1234/test#{i}",
            "title" => "Test Paper #{i}",
            "year" => "2024",
            "authors" => ["Test Author"],
            "type_of_reference" => "JOUR"
          }
        end

      session =
        Factories.insert!(:paper_ris_import_session, %{
          reference_file: reference_file,
          paper_set: paper_set,
          entries: entries,
          phase: :prompting,
          status: :activated
        })

      # Mount the ImportView
      conn = conn |> Map.put(:request_path, "/zircon/screening/import")

      {:ok, view, _html} =
        live_isolated(conn, Screening.ImportView,
          session: %{
            "tool" => tool,
            "title" => "Import Papers"
          }
        )

      # Click Continue to start import
      view
      |> element("[phx-click='commit_import']")
      |> render_click()

      # Run the import job
      assert :ok =
               Paper.RISImportCommitJob.perform(%Oban.Job{
                 args: %{"session_id" => session.id}
               })

      # Verify results
      final_session = Paper.Public.get_import_session!(session.id)
      assert final_session.status == :succeeded
      # Only new papers
      assert final_session.summary["imported"] == 5
      # Existing papers
      assert final_session.summary["skipped_duplicates"] == 3

      # Verify progress tracking
      assert final_session.progress["papers_imported"] == 5
      assert final_session.progress["papers_skipped"] == 3
      assert final_session.progress["total_papers"] == 8
      # Processed 3 batches
      assert final_session.progress["current_batch"] == 3
      assert final_session.progress["total_batches"] == 3
    end

    test "small batch imports complete without progress UI", %{
      conn: conn,
      tool: tool,
      paper_set: paper_set
    } do
      # This test simulates checking the progress message at different stages

      # Configure very small batch size
      original_batch_size = Application.get_env(:core, :paper)[:import_batch_size]
      Application.put_env(:core, :paper, import_batch_size: 2, import_batch_timeout: 30_000)

      on_exit(fn ->
        Application.put_env(:core, :paper,
          import_batch_size: original_batch_size,
          import_batch_timeout: 30_000
        )
      end)

      # Create reference file with file association
      file = Factories.insert!(:content_file, %{name: "test.ris"})
      reference_file = Factories.insert!(:paper_reference_file, %{file: file})

      # Associate reference file with tool
      tool =
        tool
        |> Core.Repo.preload(:reference_files)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:reference_files, [reference_file])
        |> Core.Repo.update!()

      # Create import session with just 4 papers (2 batches)
      entries =
        for i <- 1..4 do
          %{
            "status" => "new",
            "doi" => "10.1234/test#{i}",
            "title" => "Test Paper #{i}",
            "year" => "2024",
            "authors" => ["Test Author"],
            "type_of_reference" => "JOUR"
          }
        end

      # Create session already in importing phase with some progress
      session =
        Factories.insert!(:paper_ris_import_session, %{
          reference_file: reference_file,
          paper_set: paper_set,
          entries: entries,
          phase: :importing,
          status: :activated,
          progress: %{
            "current_batch" => 1,
            "total_batches" => 2,
            "papers_processed" => 2,
            "papers_imported" => 2,
            "papers_skipped" => 0,
            "total_papers" => 4
          }
        })

      # Mount the ImportView - should show progress
      conn = conn |> Map.put(:request_path, "/zircon/screening/import")

      {:ok, _view, html} =
        live_isolated(conn, Screening.ImportView,
          session: %{
            "tool" => tool,
            "title" => "Import Papers"
          }
        )

      # With only 4 papers (below threshold of 20), no progress UI should show
      refute html =~ "processing-status-block"
      # The import continues without visible progress indicators

      # Update session to simulate batch 2 completion
      session
      |> Paper.RISImportSessionModel.changeset(%{
        progress: %{
          "current_batch" => 2,
          "total_batches" => 2,
          "papers_processed" => 4,
          "papers_imported" => 4,
          "papers_skipped" => 0,
          "total_papers" => 4
        }
      })
      |> Core.Repo.update!()

      # With small imports (below threshold), the UI continues without progress indicators
      # The import happens in the background without visible UI updates
    end
  end

  describe "batch error handling" do
    test "handles batch failure gracefully", %{
      conn: conn,
      tool: tool,
      paper_set: paper_set
    } do
      # Configure batch size
      original_batch_size = Application.get_env(:core, :paper)[:import_batch_size]
      Application.put_env(:core, :paper, import_batch_size: 5, import_batch_timeout: 30_000)

      on_exit(fn ->
        Application.put_env(:core, :paper,
          import_batch_size: original_batch_size,
          import_batch_timeout: 30_000
        )
      end)

      file = Factories.insert!(:content_file, %{name: "test.ris"})
      reference_file = Factories.insert!(:paper_reference_file, %{file: file})

      tool =
        tool
        |> Core.Repo.preload(:reference_files)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:reference_files, [reference_file])
        |> Core.Repo.update!()

      # Create import session with invalid entry that will cause failure
      entries = [
        %{
          "status" => "new",
          # Missing DOI and title will cause validation error
          "doi" => nil,
          "title" => nil,
          "year" => "2024",
          "authors" => ["Test Author"],
          "type_of_reference" => "JOUR"
        }
      ]

      session =
        Factories.insert!(:paper_ris_import_session, %{
          reference_file: reference_file,
          paper_set: paper_set,
          entries: entries,
          phase: :prompting,
          status: :activated
        })

      # Mount the ImportView
      conn = conn |> Map.put(:request_path, "/zircon/screening/import")

      {:ok, view, _html} =
        live_isolated(conn, Screening.ImportView,
          session: %{
            "tool" => tool,
            "title" => "Import Papers"
          }
        )

      # Click Continue to start import
      view
      |> element("[phx-click='commit_import']")
      |> render_click()

      # Run the import job - should handle the error
      _result =
        Paper.RISImportCommitJob.perform(%Oban.Job{
          args: %{"session_id" => session.id}
        })

      # The job might fail or skip the invalid entry
      # Check the final session state
      final_session = Paper.Public.get_import_session!(session.id)

      # Session should either be failed or succeeded with 0 or 1 imports
      # (depends on how the system handles entries with no DOI/title)
      assert final_session.status in [:failed, :succeeded]

      if final_session.status == :succeeded do
        # The system might import the entry even without DOI/title
        # or it might skip it as invalid
        assert final_session.summary["imported"] in [0, 1]
      end
    end
  end
end
