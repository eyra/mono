defmodule Systems.Paper.RISImportCommitJobTest do
  use Core.DataCase

  alias Systems.Paper
  import Ecto.Query
  import Frameworks.Signal.TestHelper

  describe "batch processing" do
    setup do
      # Disable signal handlers for testing
      isolate_signals()
    end

    test "processes papers in batches" do
      # Create a paper set
      paper_set = Factories.insert!(:paper_set)

      # Create a reference file
      reference_file = Factories.insert!(:paper_reference_file)

      # Create an import session with 250 new papers (should be 3 batches with batch_size=100)
      entries =
        for i <- 1..250 do
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
          phase: :importing,
          status: :activated
        })

      # Execute the job
      assert :ok =
               Paper.RISImportCommitJob.perform(%Oban.Job{
                 args: %{"session_id" => session.id}
               })

      # Verify all papers were imported
      papers =
        from(p in Paper.Model,
          join: ps in Paper.SetAssoc,
          on: ps.paper_id == p.id,
          where: ps.set_id == ^paper_set.id
        )
        |> Repo.all()

      assert length(papers) == 250

      # Verify session was marked as succeeded
      updated_session = Repo.get!(Paper.RISImportSessionModel, session.id)
      assert updated_session.status == :succeeded
      assert updated_session.summary["imported"] == 250
      assert updated_session.summary["skipped_duplicates"] == 0

      # Verify progress tracking
      assert updated_session.progress["papers_imported"] == 250
      assert updated_session.progress["papers_skipped"] == 0
      assert updated_session.progress["total_papers"] == 250
      assert updated_session.progress["papers_processed"] == 250
    end

    test "handles duplicate papers correctly across batches" do
      paper_set = Factories.insert!(:paper_set)
      reference_file = Factories.insert!(:paper_reference_file)

      # Insert some existing papers
      for i <- 1..50 do
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

      # Create session with 150 papers (50 duplicates, 100 new)
      entries =
        for i <- 1..150 do
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
          phase: :importing,
          status: :activated
        })

      # Execute the job
      assert :ok =
               Paper.RISImportCommitJob.perform(%Oban.Job{
                 args: %{"session_id" => session.id}
               })

      # Verify correct number of papers
      papers =
        from(p in Paper.Model,
          join: ps in Paper.SetAssoc,
          on: ps.paper_id == p.id,
          where: ps.set_id == ^paper_set.id
        )
        |> Repo.all()

      # 50 existing + 100 new
      assert length(papers) == 150

      # Verify session summary
      updated_session = Repo.get!(Paper.RISImportSessionModel, session.id)
      assert updated_session.status == :succeeded
      assert updated_session.summary["imported"] == 100
      assert updated_session.summary["skipped_duplicates"] == 50

      # Verify progress tracking
      assert updated_session.progress["papers_imported"] == 100
      assert updated_session.progress["papers_skipped"] == 50
      assert updated_session.progress["total_papers"] == 150
      assert updated_session.progress["papers_processed"] == 150
    end
  end
end
