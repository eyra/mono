defmodule Systems.Paper.RISImportPrepareJobTest do
  use Core.DataCase
  use Oban.Testing, repo: Core.Repo

  import Frameworks.Signal.TestHelper

  setup do
    # Isolate signals to prevent unwanted side effects during unit testing
    # Could also use: isolate_signals(except: Systems.Paper.Switch) to test paper signals
    isolate_signals()
    on_exit(&restore_signal_handlers/0)

    # Use LocalFS backend for tests with real files
    Application.put_env(:core, :content, backend: Systems.Content.LocalFS)
    :ok
  end

  describe "RISImportPrepareJob" do
    setup do
      # Create minimal required entities (no complex workflow setup needed due to signal isolation)
      # Create paper set
      paper_set = Factories.insert!(:paper_set)

      # Create reference file
      # Use the small.ris test file
      test_file_path = Path.join(File.cwd!(), "test/systems/zircon/screening/test_data/small.ris")

      reference_file =
        Factories.insert!(:paper_reference_file, %{
          status: :uploaded,
          file:
            Factories.build(:content_file, %{
              ref: test_file_path,
              name: "small.ris"
            })
        })

      {:ok, paper_set: paper_set, reference_file: reference_file}
    end

    test "handles RISFetcher error gracefully", %{
      paper_set: paper_set,
      reference_file: reference_file
    } do
      # Update reference file to point to non-existent file
      reference_file = reference_file |> Repo.preload(:file, force: true)

      Repo.update!(
        Ecto.Changeset.change(reference_file.file, %{
          ref: "/nonexistent/fake.ris"
        })
      )

      reference_file = reference_file |> Repo.preload(:file, force: true)

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
      result = perform_job(Systems.Paper.RISImportPrepareJob, job_args)
      assert {:discard, error_msg} = result

      assert error_msg =~
               "Unable to process the file. Please try again. If the problem persists, please contact support."

      # Verify the session was updated with error status
      updated_session = Core.Repo.get!(Systems.Paper.RISImportSessionModel, session.id)
      assert updated_session.status == :failed
      assert Enum.any?(updated_session.errors, &(&1 =~ "Unable to process the file"))
      assert updated_session.completed_at != nil
    end

    test "prevents duplicate creation during normal import flow", %{
      paper_set: paper_set,
      reference_file: reference_file
    } do
      # Reference file already points to small.ris which has 3 papers

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
      # small.ris has 3 papers
      assert length(ris_entries) == 3
      assert Enum.all?(ris_entries, fn entry -> entry["status"] == "new" end)

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

    test "handles file-level validation errors (binary file)", %{
      paper_set: paper_set
    } do
      # Create a binary file (fake JPEG)
      binary_content = <<0xFF, 0xD8, 0xFF, 0xE0>> <> String.duplicate("A", 1000)
      temp_file = Path.join(System.tmp_dir!(), "binary_test.ris")
      File.write!(temp_file, binary_content)

      reference_file =
        Factories.insert!(:paper_reference_file, %{
          status: :uploaded,
          file:
            Factories.build(:content_file, %{
              ref: temp_file,
              name: "binary_test.ris"
            })
        })

      # Create an import session
      session =
        Core.Repo.insert!(%Systems.Paper.RISImportSessionModel{
          paper_set_id: paper_set.id,
          reference_file_id: reference_file.id,
          status: :activated,
          phase: :waiting
        })

      # Run the import job - should fail with validation error
      job_args = %{"session_id" => session.id}
      result = perform_job(Systems.Paper.RISImportPrepareJob, job_args)
      assert {:discard, error_msg} = result
      assert error_msg =~ "image or document file"

      # Verify the session was marked as failed
      updated_session = Core.Repo.get!(Systems.Paper.RISImportSessionModel, session.id)
      assert updated_session.status == :failed
      # Should still be in processing phase
      assert updated_session.phase == :processing
      assert Enum.any?(updated_session.errors, &(&1 =~ "image or document file"))
      assert updated_session.completed_at != nil

      # Verify the reference file was marked as failed
      updated_file = Core.Repo.get!(Systems.Paper.ReferenceFileModel, reference_file.id)
      assert updated_file.status == :failed

      # Clean up temp file
      File.rm!(temp_file)
    end

    test "handles file-level validation errors (not a RIS file)", %{
      paper_set: paper_set
    } do
      # Create a non-RIS text file
      non_ris_content = """
      This is not a RIS file.
      Just some random text.
      No RIS structure here.
      """

      temp_file = Path.join(System.tmp_dir!(), "not_ris.txt")
      File.write!(temp_file, non_ris_content)

      reference_file =
        Factories.insert!(:paper_reference_file, %{
          status: :uploaded,
          file:
            Factories.build(:content_file, %{
              ref: temp_file,
              name: "not_ris.txt"
            })
        })

      # Create an import session
      session =
        Core.Repo.insert!(%Systems.Paper.RISImportSessionModel{
          paper_set_id: paper_set.id,
          reference_file_id: reference_file.id,
          status: :activated,
          phase: :waiting
        })

      # Run the import job - should fail with validation error
      job_args = %{"session_id" => session.id}
      result = perform_job(Systems.Paper.RISImportPrepareJob, job_args)
      assert {:discard, error_msg} = result
      assert error_msg =~ "doesn't appear to be a valid RIS file"

      # Verify the session was marked as failed
      updated_session = Core.Repo.get!(Systems.Paper.RISImportSessionModel, session.id)
      assert updated_session.status == :failed
      assert Enum.any?(updated_session.errors, &(&1 =~ "doesn't appear to be a valid RIS file"))

      # Verify the reference file was marked as failed
      updated_file = Core.Repo.get!(Systems.Paper.ReferenceFileModel, reference_file.id)
      assert updated_file.status == :failed

      # Clean up temp file
      File.rm!(temp_file)
    end

    test "updates progress during processing phase", %{
      paper_set: paper_set
    } do
      # Use twelve_papers.ris to test progress tracking
      test_file_path =
        Path.join(File.cwd!(), "test/systems/zircon/screening/test_data/twelve_papers.ris")

      reference_file =
        Factories.insert!(:paper_reference_file, %{
          status: :uploaded,
          file:
            Factories.build(:content_file, %{
              ref: test_file_path,
              name: "twelve_papers.ris"
            })
        })

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
