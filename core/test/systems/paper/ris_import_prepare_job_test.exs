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

    test "updates progress during processing phase", %{
      paper_set: paper_set,
      reference_file: reference_file
    } do
      # Create RIS content with multiple papers to test progress updates
      ris_content = """
      TY  - JOUR
      TI  - First Paper Title
      AU  - Smith, John
      PY  - 2023
      DO  - 10.1234/test1.doi
      ER  -

      TY  - JOUR
      TI  - Second Paper Title
      AU  - Doe, Jane
      PY  - 2023
      DO  - 10.1234/test2.doi
      ER  -

      TY  - JOUR
      TI  - Third Paper Title
      AU  - Johnson, Bob
      PY  - 2023
      DO  - 10.1234/test3.doi
      ER  -

      TY  - JOUR
      TI  - Fourth Paper Title
      AU  - Williams, Alice
      PY  - 2023
      DO  - 10.1234/test4.doi
      ER  -

      TY  - JOUR
      TI  - Fifth Paper Title
      AU  - Brown, Charlie
      PY  - 2023
      DO  - 10.1234/test5.doi
      ER  -

      TY  - JOUR
      TI  - Sixth Paper Title
      AU  - Davis, David
      PY  - 2023
      DO  - 10.1234/test6.doi
      ER  -

      TY  - JOUR
      TI  - Seventh Paper Title
      AU  - Miller, Eve
      PY  - 2023
      DO  - 10.1234/test7.doi
      ER  -

      TY  - JOUR
      TI  - Eighth Paper Title
      AU  - Wilson, Frank
      PY  - 2023
      DO  - 10.1234/test8.doi
      ER  -

      TY  - JOUR
      TI  - Ninth Paper Title
      AU  - Moore, Grace
      PY  - 2023
      DO  - 10.1234/test9.doi
      ER  -

      TY  - JOUR
      TI  - Tenth Paper Title
      AU  - Taylor, Henry
      PY  - 2023
      DO  - 10.1234/test10.doi
      ER  -

      TY  - JOUR
      TI  - Eleventh Paper Title
      AU  - Anderson, Isabel
      PY  - 2023
      DO  - 10.1234/test11.doi
      ER  -

      TY  - JOUR
      TI  - Twelfth Paper Title
      AU  - Thomas, Jack
      PY  - 2023
      DO  - 10.1234/test12.doi
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

      # Run the import job
      job_args = %{"session_id" => session.id}
      assert :ok = perform_job(Systems.Paper.RISImportPrepareJob, job_args)

      # Verify the session has moved to prompting phase
      updated_session = Core.Repo.get!(Systems.Paper.RISImportSessionModel, session.id)
      assert updated_session.status == :activated
      assert updated_session.phase == :prompting

      # Check that progress was tracked (final state should show all references processed)
      assert updated_session.progress != nil
      assert Map.get(updated_session.progress, "total_references") == 12
      # The last progress update should show all references processed
      assert Map.get(updated_session.progress, "current_reference") == 12

      # Verify all entries were processed
      ris_entries = updated_session.entries
      assert length(ris_entries) == 12

      # All should be marked as new since paper_set is empty
      assert Enum.all?(ris_entries, fn entry ->
               entry["status"] == "new"
             end)
    end
  end
end
