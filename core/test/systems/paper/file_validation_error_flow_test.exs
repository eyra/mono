defmodule Systems.Paper.FileValidationErrorFlowTest do
  @moduledoc """
  Test the complete flow when a file-level validation error occurs.
  Ensures that:
  1. The job fails with the validation error
  2. The session is marked as failed
  3. The reference file is marked as failed
  4. The error message is stored and can be displayed
  """

  use Core.DataCase
  use Oban.Testing, repo: Core.Repo

  import Frameworks.Signal.TestHelper

  alias Systems.Paper

  setup do
    isolate_signals()
    on_exit(&restore_signal_handlers/0)

    # Use LocalFS backend for tests with real files
    Application.put_env(:core, :content, backend: Systems.Content.LocalFS)

    # Create paper set
    paper_set = Factories.insert!(:paper_set)

    {:ok, paper_set: paper_set}
  end

  describe "file-level validation error flow" do
    test "invalid file format fails immediately without prompting", %{paper_set: paper_set} do
      # Create a non-RIS file
      invalid_content = """
      This is not a RIS file.
      Just random text without any RIS structure.
      No TY tags, no ER tags, nothing.
      """

      temp_file = Path.join(System.tmp_dir!(), "invalid_file.txt")
      File.write!(temp_file, invalid_content)

      reference_file =
        Factories.insert!(:paper_reference_file, %{
          status: :uploaded,
          file:
            Factories.build(:content_file, %{
              ref: temp_file,
              name: "invalid_file.txt"
            })
        })

      # Create import session
      session =
        Core.Repo.insert!(%Paper.RISImportSessionModel{
          paper_set_id: paper_set.id,
          reference_file_id: reference_file.id,
          status: :activated,
          phase: :waiting
        })

      # Run the import job
      job_args = %{"session_id" => session.id}
      result = perform_job(Paper.RISImportPrepareJob, job_args)

      # Job should fail with validation error
      assert {:discard, error_msg} = result
      assert error_msg =~ "doesn't appear to be a valid RIS file"

      # Session should be failed, not in prompting
      updated_session = Core.Repo.get!(Paper.RISImportSessionModel, session.id)
      assert updated_session.status == :failed
      refute updated_session.status == :activated
      refute updated_session.phase == :prompting
      assert Enum.any?(updated_session.errors, &(&1 =~ "doesn't appear to be a valid RIS file"))

      # Reference file should be marked as failed
      updated_file = Core.Repo.get!(Paper.ReferenceFileModel, reference_file.id)
      assert updated_file.status == :failed

      # No entries should have been created (no prompting data)
      assert updated_session.entries == nil or updated_session.entries == []

      # Clean up
      File.rm!(temp_file)
    end

    test "binary file fails immediately without prompting", %{paper_set: paper_set} do
      # Create a binary file (simulated image)
      binary_content = <<0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10>> <> String.duplicate(<<0xFF>>, 500)

      temp_file = Path.join(System.tmp_dir!(), "image.jpg")
      File.write!(temp_file, binary_content)

      reference_file =
        Factories.insert!(:paper_reference_file, %{
          status: :uploaded,
          file:
            Factories.build(:content_file, %{
              ref: temp_file,
              name: "image.jpg"
            })
        })

      # Create import session
      session =
        Core.Repo.insert!(%Paper.RISImportSessionModel{
          paper_set_id: paper_set.id,
          reference_file_id: reference_file.id,
          status: :activated,
          phase: :waiting
        })

      # Run the import job
      job_args = %{"session_id" => session.id}
      result = perform_job(Paper.RISImportPrepareJob, job_args)

      # Job should fail with binary file error
      assert {:discard, error_msg} = result
      assert error_msg =~ "image or document file"

      # Session should be failed
      updated_session = Core.Repo.get!(Paper.RISImportSessionModel, session.id)
      assert updated_session.status == :failed
      assert Enum.any?(updated_session.errors, &(&1 =~ "image or document file"))

      # Reference file should be marked as failed
      updated_file = Core.Repo.get!(Paper.ReferenceFileModel, reference_file.id)
      assert updated_file.status == :failed

      # Clean up
      File.rm!(temp_file)
    end

    test "valid RIS with parse errors goes to prompting", %{paper_set: paper_set} do
      # Create a RIS file with some invalid entries
      mixed_content = """
      TY  - JOUR
      TI  - Valid Entry
      AU  - Smith, John
      PY  - 2023
      ER  -

      TY  - INVALID_TYPE
      TI  - This will cause an error
      ER  -

      TY  - BOOK
      TI  - Another Valid Entry
      AU  - Doe, Jane
      PY  - 2024
      ER  -
      """

      temp_file = Path.join(System.tmp_dir!(), "mixed.ris")
      File.write!(temp_file, mixed_content)

      reference_file =
        Factories.insert!(:paper_reference_file, %{
          status: :uploaded,
          file:
            Factories.build(:content_file, %{
              ref: temp_file,
              name: "mixed.ris"
            })
        })

      # Create import session
      session =
        Core.Repo.insert!(%Paper.RISImportSessionModel{
          paper_set_id: paper_set.id,
          reference_file_id: reference_file.id,
          status: :activated,
          phase: :waiting
        })

      # Run the import job
      job_args = %{"session_id" => session.id}
      result = perform_job(Paper.RISImportPrepareJob, job_args)

      # Job should succeed (reference-level errors don't fail the job)
      assert :ok = result

      # Session should be in prompting phase
      updated_session = Core.Repo.get!(Paper.RISImportSessionModel, session.id)
      assert updated_session.status == :activated
      assert updated_session.phase == :prompting

      # Should have entries (2 valid, 1 error)
      assert length(updated_session.entries) == 3

      # Reference file should still be uploaded (not failed)
      updated_file = Core.Repo.get!(Paper.ReferenceFileModel, reference_file.id)
      assert updated_file.status == :uploaded

      # Clean up
      File.rm!(temp_file)
    end
  end
end
