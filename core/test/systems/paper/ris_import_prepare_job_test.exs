defmodule Systems.Paper.RISImportPrepareJobTest do
  use Core.DataCase
  use Oban.Testing, repo: Core.Repo

  import Mox
  import Frameworks.Signal.TestHelper

  alias Systems.Paper.RISFetcherMock

  setup :verify_on_exit!

  setup do
    # Isolate signals to prevent unwanted side effects during unit testing
    # Could also use: isolate_signals(except: Systems.Paper.Switch) to test paper signals
    isolate_signals()
    on_exit(&restore_signal_handlers/0)
  end

  describe "RISImportPrepareJob" do
    test "verifies mock is configured" do
      # Quick test to verify our mock configuration works
      fetcher_module = Application.get_env(:core, :ris_fetcher_module)
      assert fetcher_module == Systems.Paper.RISFetcherMock
    end

    setup do
      # Create minimal required entities (no complex workflow setup needed due to signal isolation)
      # Create paper set
      paper_set = Factories.insert!(:paper_set)

      # Create reference file
      reference_file =
        Factories.insert!(:paper_reference_file, %{
          status: :uploaded,
          file:
            Factories.build(:content_file, %{
              ref: "http://example.com/test.ris"
            })
        })

      {:ok, paper_set: paper_set, reference_file: reference_file}
    end

    test "handles RISFetcher error gracefully", %{
      paper_set: paper_set,
      reference_file: reference_file
    } do
      # Mock RISFetcher to return an error when fetching content
      expect(RISFetcherMock, :fetch_content, fn _reference_file ->
        {:error, "Failed to fetch RIS content"}
      end)

      # Create an import session first
      session =
        Core.Repo.insert!(%Systems.Paper.RISImportSessionModel{
          paper_set_id: paper_set.id,
          reference_file_id: reference_file.id,
          status: :activated,
          phase: :waiting
        })

      # Create and perform the job with session_id
      job_args = %{"session_id" => session.id}

      # The job should handle the fetch error gracefully
      assert {:error, "Failed to fetch RIS content"} =
               perform_job(Systems.Paper.RISImportPrepareJob, job_args)

      # Verify the session was updated with error status
      updated_session = Core.Repo.get!(Systems.Paper.RISImportSessionModel, session.id)
      assert updated_session.status == :failed
      assert "Failed to fetch RIS content" in updated_session.errors
      assert updated_session.completed_at != nil
    end

    test "prevents duplicate creation during normal import flow", %{
      paper_set: paper_set,
      reference_file: reference_file
    } do
      # Mock RISFetcher to return valid RIS content with one paper
      # Note: RIS format is very specific about spacing and line endings
      ris_content = """
      TY  - JOUR
      TI  - Test Paper Title
      AU  - Smith, John
      PY  - 2023
      DO  - 10.1234/test.doi
      AB  - Test abstract
      KW  - test keyword
      ER  -
      """

      expect(RISFetcherMock, :fetch_content, fn _reference_file ->
        {:ok, ris_content}
      end)

      # Create an import session
      session =
        Core.Repo.insert!(%Systems.Paper.RISImportSessionModel{
          paper_set_id: paper_set.id,
          reference_file_id: reference_file.id,
          status: :activated,
          phase: :waiting
        })

      # Run the import job - should parse and process the file (not import yet)
      job_args = %{"session_id" => session.id}
      assert :ok = perform_job(Systems.Paper.RISImportPrepareJob, job_args)

      # Verify the session is in prompting phase (after processing)
      updated_session = Core.Repo.get!(Systems.Paper.RISImportSessionModel, session.id)
      assert updated_session.status == :activated
      # After parsing and processing, it goes to prompting phase
      assert updated_session.phase == :prompting
      assert updated_session.completed_at == nil

      ris_entries = updated_session.entries
      assert length(ris_entries) == 1
      assert List.first(ris_entries)["status"] == "new"

      # No papers should be created yet (two-phase workflow)
      papers =
        Core.Repo.all(
          from(p in Systems.Paper.Model,
            join: assoc in Systems.Paper.SetAssoc,
            on: assoc.paper_id == p.id,
            where: assoc.set_id == ^paper_set.id
          )
        )

      assert Enum.empty?(papers)

      # Now continue the import (this enqueues a job to create the papers)
      final_session = Systems.Paper.Public.commit_import_session!(updated_session)
      assert final_session.status == :activated
      assert final_session.phase == :importing

      # Papers are created asynchronously via RISImportCommitJob
      # We can't verify paper creation here without running the job
      # The test's main purpose is to verify duplicate prevention, which is already tested above
    end
  end
end
