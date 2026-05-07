defmodule Systems.Zircon.Screening.FileSelectorClearTest do
  use CoreWeb.ConnCase, async: false
  import Frameworks.Signal.TestHelper

  alias Core.Repo
  alias Systems.Paper
  alias Systems.Zircon

  setup do
    # Isolate all signals to prevent unwanted propagation
    isolate_signals()

    # Create required entities
    auth_node = Factories.insert!(:auth_node)

    tool =
      Factories.insert!(:zircon_screening_tool, %{
        auth_node: auth_node
      })

    user = Factories.insert!(:member)

    %{tool: tool, user: user}
  end

  describe "file selector after abort" do
    test "file selector shows nil after aborting from prompting phase with empty results", %{
      tool: tool
    } do
      # Setup: Create reference file and session in prompting phase with empty results
      reference_file =
        Factories.insert!(:paper_reference_file, %{
          status: :uploaded,
          file:
            Factories.build(:content_file, %{
              ref: "http://example.com/test.ris",
              name: "test.ris"
            })
        })

      Repo.insert!(%Systems.Zircon.Screening.ToolReferenceFileAssoc{
        tool: tool,
        reference_file: reference_file
      })

      paper_set =
        Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id
        })

      import_session =
        Factories.insert!(:paper_ris_import_session, %{
          status: :activated,
          phase: :prompting,
          reference_file: reference_file,
          paper_set: paper_set,
          # Empty - no new papers
          entries: [],
          errors: []
        })

      # BEFORE ABORT: View model should show the session and file
      assigns = %{}
      vm_before = Zircon.Screening.ImportViewBuilder.view_model(tool, assigns)

      # Should show file selector and prompting summary
      {:import_section, import_section} =
        Enum.find(vm_before.stack, fn {type, _} -> type == :import_section end)

      # Should show both file selector and prompting summary
      file_selector_block =
        import_section.stack |> Enum.find(fn {type, _} -> type == :import_file_selector end)

      prompting_summary_block =
        import_section.stack |> Enum.find(fn {type, _} -> type == :prompting_summary end)

      assert file_selector_block != nil, "Should show file selector in prompting phase"
      assert prompting_summary_block != nil, "Should show prompting summary before abort"
      assert vm_before.active_filename == "test.ris"
      assert vm_before.active_file_url == "http://example.com/test.ris"

      # ABORT THE SESSION
      Zircon.Public.abort_import!(import_session)

      # AFTER ABORT: View model should show empty file selector
      # Reload tool to ensure fresh data
      tool = Repo.get!(Zircon.Screening.ToolModel, tool.id)
      vm_after = Zircon.Screening.ImportViewBuilder.view_model(tool, assigns)

      # Should now show file selector (not import session)
      {:import_section, import_section_after} =
        Enum.find(vm_after.stack, fn {type, _} -> type == :import_section end)

      [{block_type_after, _}] = import_section_after.stack
      assert block_type_after == :import_file_selector, "Should show file selector after abort"

      # THIS IS THE KEY ASSERTION - File should be cleared
      assert vm_after.active_filename == nil,
             "File selector should be empty after abort, but shows: #{vm_after.active_filename}"

      assert vm_after.active_file_url == nil,
             "File URL should be nil after abort, but shows: #{vm_after.active_file_url}"

      # Verify database state
      ref_file = Repo.get!(Paper.ReferenceFileModel, reference_file.id)
      assert ref_file.status == :archived, "Reference file should be archived"

      session = Repo.get!(Paper.RISImportSessionModel, import_session.id)
      assert session.status == :aborted, "Session should be aborted"

      # Verify no active sessions remain
      assert Paper.Public.get_active_import_session_for_reference_file(reference_file.id) == nil
    end

    test "multiple reference files - only active one is archived", %{
      tool: tool
    } do
      # Create multiple reference files
      ref_file_1 =
        Factories.insert!(:paper_reference_file, %{
          # Already processed
          status: :processed,
          file:
            Factories.build(:content_file, %{
              ref: "http://example.com/old.ris",
              name: "old.ris"
            })
        })

      ref_file_2 =
        Factories.insert!(:paper_reference_file, %{
          # Current active file
          status: :uploaded,
          file:
            Factories.build(:content_file, %{
              ref: "http://example.com/current.ris",
              name: "current.ris"
            })
        })

      ref_file_3 =
        Factories.insert!(:paper_reference_file, %{
          # Another uploaded file (shouldn't happen normally)
          status: :uploaded,
          file:
            Factories.build(:content_file, %{
              ref: "http://example.com/extra.ris",
              name: "extra.ris"
            })
        })

      # Associate all with tool
      [ref_file_1, ref_file_2, ref_file_3]
      |> Enum.each(fn rf ->
        Repo.insert!(%Systems.Zircon.Screening.ToolReferenceFileAssoc{
          tool: tool,
          reference_file: rf
        })
      end)

      paper_set =
        Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id
        })

      # Create session only for ref_file_2
      import_session =
        Factories.insert!(:paper_ris_import_session, %{
          status: :activated,
          phase: :prompting,
          reference_file: ref_file_2,
          paper_set: paper_set,
          entries: [],
          errors: []
        })

      # Check view model before abort
      assigns = %{}
      vm_before = Zircon.Screening.ImportViewBuilder.view_model(tool, assigns)

      # Should show current.ris from the active session
      assert vm_before.active_filename == "current.ris"

      # Abort the session
      Zircon.Public.abort_import!(import_session)

      # Check view model after abort
      tool = Repo.get!(Zircon.Screening.ToolModel, tool.id)
      vm_after = Zircon.Screening.ImportViewBuilder.view_model(tool, assigns)

      # Check status of all files
      ref_file_1_after = Repo.get!(Paper.ReferenceFileModel, ref_file_1.id)
      ref_file_2_after = Repo.get!(Paper.ReferenceFileModel, ref_file_2.id)
      ref_file_3_after = Repo.get!(Paper.ReferenceFileModel, ref_file_3.id)

      assert ref_file_1_after.status == :processed, "Old processed file should remain processed"
      assert ref_file_2_after.status == :archived, "Active session file should be archived"
      assert ref_file_3_after.status == :uploaded, "Other uploaded file should remain uploaded"

      # After abort, should show the other uploaded file (extra.ris)
      assert vm_after.active_filename == "extra.ris",
             "Should show the remaining uploaded file after abort"
    end
  end
end
