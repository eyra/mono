defmodule Systems.Zircon.Screening.ImportViewBuilderTest do
  use Core.DataCase
  alias Systems.Zircon.Screening.ImportViewBuilder

  # Helper function to extract import buttons assigns from nested structure
  defp get_import_buttons_assigns(stack) do
    with {_, import_section_assigns} <-
           Enum.find(stack, fn {type, _} -> type == :import_section end),
         {_, import_buttons_assigns} <-
           Enum.find(import_section_assigns.stack, fn {type, _} -> type == :import_buttons end) do
      import_buttons_assigns
    else
      _ -> nil
    end
  end

  # Helper function to check if a block type exists in the import section stack
  defp has_block_in_import_section?(stack, block_type) do
    case Enum.find(stack, fn {type, _} -> type == :import_section end) do
      {_, import_section_assigns} ->
        Enum.any?(import_section_assigns.stack, fn {type, _} -> type == block_type end)

      nil ->
        false
    end
  end

  describe "view_model/2 basic functionality" do
    test "creates basic view model for tool with no papers" do
      tool = Core.Factories.insert!(:zircon_screening_tool)
      assigns = %{}

      result = ImportViewBuilder.view_model(tool, assigns)

      assert %{stack: stack, active_filename: nil, active_file_url: nil} = result
      # header and import_section blocks (no content when 0 papers)
      assert length(stack) == 2

      # Check header block
      {header_type, header_assigns} = Enum.at(stack, 0)
      assert header_type == :header
      assert header_assigns.title == "Import Papers"
      assert header_assigns.paper_count == 0

      # Check import_section block (now second in stack)
      {import_section_type, import_section_assigns} = Enum.at(stack, 1)
      assert import_section_type == :import_section

      # Check nested blocks in import_section stack
      # Should have both file selector and import buttons when no session and no file
      assert length(import_section_assigns.stack) >= 1

      # Check file selector exists
      {file_selector_type, _file_selector_assigns} =
        import_section_assigns.stack
        |> Enum.find(fn {type, _} -> type == :import_file_selector end)

      assert file_selector_type == :import_file_selector

      # No content block when there are no papers
    end

    test "creates view model for tool with papers" do
      # Create tool first to get its ID
      tool = Core.Factories.insert!(:zircon_screening_tool)

      # Create papers
      paper1 = Core.Factories.insert!(:paper, %{title: "Test Paper 1"})
      paper2 = Core.Factories.insert!(:paper, %{title: "Test Paper 2"})

      # Create paper set with papers, using the tool's category and identifier
      _paper_set =
        Core.Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id,
          papers: [paper1, paper2]
        })

      assigns = %{}

      result = ImportViewBuilder.view_model(tool, assigns)

      assert %{stack: stack} = result

      # Check header block
      {_, header_assigns} = Enum.at(stack, 0)
      assert header_assigns.paper_count == 2

      # Check import_section block (now second in stack)
      {import_section_type, _} = Enum.at(stack, 1)
      assert import_section_type == :import_section

      # Check content block (now third in stack)
      {content_type, content_assigns} = Enum.at(stack, 2)
      assert content_type == :content
      # Has papers
      refute is_nil(content_assigns.paper_set_view)
    end

    test "extracts title from assigns with different structures" do
      tool = Core.Factories.insert!(:zircon_screening_tool)

      # Test direct title
      assigns = %{"title" => "Custom Title"}
      result = ImportViewBuilder.view_model(tool, assigns)
      {_, header_assigns} = result.stack |> Enum.find(fn {type, _} -> type == :header end)
      assert header_assigns.title == "Custom Title"

      # Test session title
      assigns = %{session: %{"title" => "Session Title"}}
      result = ImportViewBuilder.view_model(tool, assigns)
      {_, header_assigns} = result.stack |> Enum.find(fn {type, _} -> type == :header end)
      assert header_assigns.title == "Session Title"

      # Test default title
      assigns = %{}
      result = ImportViewBuilder.view_model(tool, assigns)
      {_, header_assigns} = result.stack |> Enum.find(fn {type, _} -> type == :header end)
      assert header_assigns.title == "Import Papers"
    end
  end

  describe "import status determination" do
    test "returns idle status when no reference files exist" do
      tool = Core.Factories.insert!(:zircon_screening_tool)
      assigns = %{}

      result = ImportViewBuilder.view_model(tool, assigns)

      {_, _header_assigns} = result.stack |> Enum.find(fn {type, _} -> type == :header end)
      # No file uploaded, so should have file selector but no import buttons
      assert has_block_in_import_section?(result.stack, :import_file_selector)
      refute has_block_in_import_section?(result.stack, :import_buttons)
      # header and import_section (no content when 0 papers)
      assert length(result.stack) == 2
    end

    test "returns active import status when session is running" do
      # Create reference file
      reference_file = Core.Factories.insert!(:paper_reference_file)

      # Create tool with reference file
      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      # Create paper set with the tool's category and identifier
      paper_set =
        Core.Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id
        })

      # Create active import session
      _import_session =
        Core.Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :parsing
        })

      assigns = %{}

      result = ImportViewBuilder.view_model(tool, assigns)

      {_, _header_assigns} = result.stack |> Enum.find(fn {type, _} -> type == :header end)
      # Button is not shown during active imports - it's handled in the processing_status block
      # header and import_section (no content when 0 papers)
      assert length(result.stack) == 2

      # Check processing_status block exists nested in import_section
      {_, import_section} = result.stack |> Enum.find(fn {type, _} -> type == :import_section end)

      processing_status_block =
        import_section.stack |> Enum.find(fn {type, _} -> type == :processing_status end)

      assert processing_status_block != nil
    end
  end

  describe "button configuration" do
    test "includes import session block during active import phases" do
      active_phases = [:waiting, :parsing, :processing, :importing]

      for phase <- active_phases do
        # Create reference file
        reference_file = Core.Factories.insert!(:paper_reference_file)

        # Create tool with reference file
        tool =
          Core.Factories.insert!(:zircon_screening_tool, %{
            reference_files: [reference_file]
          })

        # Create paper set with the tool's category and identifier
        paper_set =
          Core.Factories.insert!(:paper_set, %{
            category: :zircon_screening_tool,
            identifier: tool.id
          })

        # Create import session with specific phase
        import_session =
          Core.Factories.insert!(:paper_ris_import_session, %{
            paper_set: paper_set,
            reference_file: reference_file,
            status: :activated,
            phase: phase
          })

        result = ImportViewBuilder.view_model(tool, %{})

        # During active imports, the processing_status block should be present nested in import_section
        {_, import_section} =
          result.stack |> Enum.find(fn {type, _} -> type == :import_section end)

        processing_status_block =
          import_section.stack |> Enum.find(fn {type, _} -> type == :processing_status end)

        assert processing_status_block != nil,
               "Expected processing_status block for phase #{phase}"

        # When no papers, we only have 2 blocks (header and import_section)
        assert length(result.stack) >= 2,
               "Expected at least 2 blocks in stack (header, import_section) for active phase #{phase}"

        # Clean up for next iteration
        Core.Repo.delete!(import_session)
      end
    end

    test "shows normal button when idle or completed" do
      tool = Core.Factories.insert!(:zircon_screening_tool)
      assigns = %{}

      result = ImportViewBuilder.view_model(tool, assigns)

      # No file uploaded, so should have file selector but no import buttons
      assert has_block_in_import_section?(result.stack, :import_file_selector)
      refute has_block_in_import_section?(result.stack, :import_buttons)
    end
  end

  describe "import session view" do
    test "shows import session view for active sessions" do
      reference_file = Core.Factories.insert!(:paper_reference_file)

      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      paper_set =
        Core.Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id
        })

      phases = [:waiting, :parsing, :processing, :importing]

      for phase <- phases do
        # Create session with specific phase
        session =
          Core.Factories.insert!(:paper_ris_import_session, %{
            paper_set: paper_set,
            reference_file: reference_file,
            status: :activated,
            phase: phase
          })

        result = ImportViewBuilder.view_model(tool, %{})

        # Should have processing status for active processing sessions
        {_, import_section} =
          result.stack |> Enum.find(fn {type, _} -> type == :import_section end)

        session_block =
          import_section.stack |> Enum.find(fn {type, _} -> type == :processing_status end)

        assert session_block, "Should have processing status block for phase #{phase}"

        # Clean up for next iteration
        Core.Repo.delete!(session)
      end
    end
  end

  describe "display state logic" do
    test "no content block when no papers" do
      tool = Core.Factories.insert!(:zircon_screening_tool)

      result = ImportViewBuilder.view_model(tool, %{})

      # No content block should exist when there are no papers
      content_block = result.stack |> Enum.find(fn {type, _} -> type == :content end)
      assert content_block == nil
    end

    test "includes content block when papers exist" do
      # Create tool first to get its ID
      tool = Core.Factories.insert!(:zircon_screening_tool)

      # Create paper
      paper = Core.Factories.insert!(:paper)

      # Create paper set with papers, using the tool's category and identifier
      _paper_set =
        Core.Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id,
          papers: [paper]
        })

      result = ImportViewBuilder.view_model(tool, %{})

      # Content block should exist when there are papers
      {content_type, content_assigns} =
        result.stack |> Enum.find(fn {type, _} -> type == :content end)

      assert content_type == :content
      refute is_nil(content_assigns.paper_set_view)
    end
  end

  describe "file information extraction" do
    test "returns nil file info when no reference files" do
      tool = Core.Factories.insert!(:zircon_screening_tool)

      result = ImportViewBuilder.view_model(tool, %{})

      assert result.active_filename == nil
      assert result.active_file_url == nil
    end

    test "extracts file info from uploaded reference files" do
      filename = "test_file.ris"
      url = "http://example.com/test_file.ris"

      # Create reference file with specific filename and url
      reference_file =
        Core.Factories.insert!(:paper_reference_file, %{
          file:
            Core.Factories.build(:content_file, %{
              name: filename,
              ref: url
            })
        })

      # Create tool with the reference file
      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      result = ImportViewBuilder.view_model(tool, %{})

      assert result.active_filename == filename
      assert result.active_file_url == url
    end

    test "prefers active session file info over uploaded files" do
      # Create uploaded reference file
      uploaded_ref_file =
        Core.Factories.insert!(:paper_reference_file, %{
          file:
            Core.Factories.build(:content_file, %{
              name: "uploaded.ris",
              ref: "http://example.com/uploaded.ris"
            })
        })

      # Create active session reference file
      session_ref_file =
        Core.Factories.insert!(:paper_reference_file, %{
          file:
            Core.Factories.build(:content_file, %{
              name: "session.ris",
              ref: "http://example.com/session.ris"
            })
        })

      # Create tool with both reference files
      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [uploaded_ref_file, session_ref_file]
        })

      # Create paper set with the tool's category and identifier
      paper_set =
        Core.Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id
        })

      # Create active import session with the session reference file
      _import_session =
        Core.Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: session_ref_file,
          status: :activated,
          phase: :parsing
        })

      result = ImportViewBuilder.view_model(tool, %{})

      # Should prefer the active session file info
      assert result.active_filename == "session.ris"
      assert result.active_file_url == "http://example.com/session.ris"
    end
  end

  describe "import session view logic" do
    test "includes import session block only for active sessions" do
      reference_file = Core.Factories.insert!(:paper_reference_file)

      # Create tool with reference file
      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      paper_set =
        Core.Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id
        })

      # Test with active session
      active_session =
        Core.Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :processing
        })

      result = ImportViewBuilder.view_model(tool, %{})

      # header and import_section (no content when 0 papers)
      assert length(result.stack) == 2
      {_, import_section} = result.stack |> Enum.find(fn {type, _} -> type == :import_section end)
      # Check that processing_status is nested inside import_section
      processing_status_block =
        import_section.stack |> Enum.find(fn {type, _} -> type == :processing_status end)

      assert processing_status_block != nil

      # Clean up and test with completed session
      Core.Repo.delete!(active_session)

      _completed_session =
        Core.Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :succeeded,
          phase: :importing
        })

      result = ImportViewBuilder.view_model(tool, %{})

      # header and import_section (no content when 0 papers)
      assert length(result.stack) == 2
      {_, import_section} = result.stack |> Enum.find(fn {type, _} -> type == :import_section end)

      # Check that there's no import_session or processing_status nested in import_section (should have file selector instead)
      import_session_block =
        import_section.stack |> Enum.find(fn {type, _} -> type == :import_session end)

      processing_status_block =
        import_section.stack |> Enum.find(fn {type, _} -> type == :processing_status end)

      assert import_session_block == nil
      assert processing_status_block == nil

      file_selector_block =
        import_section.stack |> Enum.find(fn {type, _} -> type == :import_file_selector end)

      assert file_selector_block != nil
    end
  end

  describe "import button visibility logic" do
    test "shows import buttons when no active session and filename exists" do
      # Create tool with uploaded file
      reference_file =
        Core.Factories.insert!(:paper_reference_file, %{
          file:
            Core.Factories.build(:content_file, %{
              name: "test.ris",
              ref: "http://example.com/test.ris"
            })
        })

      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      result = ImportViewBuilder.view_model(tool, %{})

      # Should have import buttons block
      assert has_block_in_import_section?(result.stack, :import_buttons)

      buttons = get_import_buttons_assigns(result.stack)
      assert buttons != nil
      assert buttons.import_button_face.type == :primary
      assert buttons.import_button_enabled == true
    end

    test "does not show import buttons when no filename" do
      # Create tool without any reference files
      tool = Core.Factories.insert!(:zircon_screening_tool)

      result = ImportViewBuilder.view_model(tool, %{})

      # Should NOT have import buttons block (no file uploaded)
      refute has_block_in_import_section?(result.stack, :import_buttons)
    end

    test "does not show import buttons during active session" do
      reference_file =
        Core.Factories.insert!(:paper_reference_file, %{
          file:
            Core.Factories.build(:content_file, %{
              name: "test.ris",
              ref: "http://example.com/test.ris"
            })
        })

      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      paper_set =
        Core.Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id
        })

      # Create active session
      _session =
        Core.Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :processing
        })

      result = ImportViewBuilder.view_model(tool, %{})

      # Should NOT have import buttons block during active session
      refute has_block_in_import_section?(result.stack, :import_buttons)
    end

    test "shows file selector during processing phases" do
      reference_file =
        Core.Factories.insert!(:paper_reference_file, %{
          file:
            Core.Factories.build(:content_file, %{
              name: "test.ris",
              ref: "http://example.com/test.ris"
            })
        })

      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      paper_set =
        Core.Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id
        })

      processing_phases = [:waiting, :parsing, :processing]

      for phase <- processing_phases do
        # Create session with specific phase
        session =
          Core.Factories.insert!(:paper_ris_import_session, %{
            paper_set: paper_set,
            reference_file: reference_file,
            status: :activated,
            phase: phase
          })

        result = ImportViewBuilder.view_model(tool, %{})

        # Should show file selector during processing phases
        assert has_block_in_import_section?(result.stack, :import_file_selector),
               "Expected file selector for phase #{phase}"

        # Import session is embedded separately, not as a block in the stack
        # The processing/waiting state is shown in the button with loading spinner

        # But NO import buttons
        refute has_block_in_import_section?(result.stack, :import_buttons),
               "Should not have import buttons for phase #{phase}"

        # Clean up for next iteration
        Core.Repo.delete!(session)
      end
    end

    test "shows file selector during prompting phase with errors" do
      reference_file =
        Core.Factories.insert!(:paper_reference_file, %{
          file:
            Core.Factories.build(:content_file, %{
              name: "test.ris",
              ref: "http://example.com/test.ris"
            })
        })

      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      paper_set =
        Core.Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id
        })

      # Create session in prompting phase with errors
      _session =
        Core.Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [
            %{"status" => "error", "error" => %{"line" => 1, "error" => "Test error"}}
          ]
        })

      result = ImportViewBuilder.view_model(tool, %{})

      # Should show file selector when there are errors
      assert has_block_in_import_section?(result.stack, :import_file_selector)

      # Should also show prompting summary
      assert has_block_in_import_section?(result.stack, :prompting_summary)

      # But NO import buttons
      refute has_block_in_import_section?(result.stack, :import_buttons)
    end

    test "shows file selector during prompting phase without errors" do
      reference_file =
        Core.Factories.insert!(:paper_reference_file, %{
          file:
            Core.Factories.build(:content_file, %{
              name: "test.ris",
              ref: "http://example.com/test.ris"
            })
        })

      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      paper_set =
        Core.Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id
        })

      # Create session in prompting phase with new papers (no errors)
      _session =
        Core.Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [
            %{"status" => "new", "title" => "Test Paper"}
          ]
        })

      result = ImportViewBuilder.view_model(tool, %{})

      # Should show file selector during prompting phase (allows user to replace file)
      assert has_block_in_import_section?(result.stack, :import_file_selector)

      # Should show prompting summary
      assert has_block_in_import_section?(result.stack, :prompting_summary)

      # No import buttons
      refute has_block_in_import_section?(result.stack, :import_buttons)
    end
  end

  describe "prompting phase with mixed results" do
    test "shows prompting summary when session has both errors and new papers" do
      # Create reference file
      reference_file =
        Core.Factories.insert!(:paper_reference_file, %{
          file:
            Core.Factories.build(:content_file, %{
              name: "mixed_results.ris",
              ref: "http://example.com/mixed.ris"
            })
        })

      # Create tool with reference file
      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      paper_set =
        Core.Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id
        })

      # Create session in prompting phase with both errors and new papers
      _session =
        Core.Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [
            %{"status" => "new", "title" => "New Paper 1", "doi" => "10.1234/test1"},
            %{"status" => "error", "error" => "Parse error on line 15"},
            %{"status" => "new", "title" => "New Paper 2", "doi" => "10.1234/test2"},
            %{"status" => "existing", "title" => "Existing Paper"},
            %{"status" => "error", "error" => "Invalid format"}
          ]
        })

      result = ImportViewBuilder.view_model(tool, %{})

      # Should have header and import_section blocks (no content when 0 papers imported yet)
      assert length(result.stack) == 2

      # Check import_section contains prompting_summary
      {_, import_section} = result.stack |> Enum.find(fn {type, _} -> type == :import_section end)

      prompting_summary =
        import_section.stack |> Enum.find(fn {type, _} -> type == :prompting_summary end)

      assert prompting_summary != nil

      # Check prompting summary contains correct counts
      {_, summary_assigns} = prompting_summary
      assert summary_assigns.error_count == 2
      assert summary_assigns.new_paper_count == 2

      # Should have details button since there are results
      assert summary_assigns.details_button != nil

      # Should have Continue button since there are new papers
      assert length(summary_assigns.buttons) == 1
      continue_button = hd(summary_assigns.buttons)
      assert continue_button.action.event == "commit_import"

      # Check that prompting_session_id is set in view model
      assert Map.has_key?(result, :prompting_session_id)
    end

    test "shows prompting summary with only errors (no new papers)" do
      reference_file =
        Core.Factories.insert!(:paper_reference_file, %{
          file:
            Core.Factories.build(:content_file, %{
              name: "errors_only.ris",
              ref: "http://example.com/errors.ris"
            })
        })

      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [reference_file]
        })

      paper_set =
        Core.Factories.insert!(:paper_set, %{
          category: :zircon_screening_tool,
          identifier: tool.id
        })

      # Create session with only errors
      _session =
        Core.Factories.insert!(:paper_ris_import_session, %{
          paper_set: paper_set,
          reference_file: reference_file,
          status: :activated,
          phase: :prompting,
          entries: [
            %{"status" => "error", "error" => "Parse error 1"},
            %{"status" => "error", "error" => "Parse error 2"}
          ]
        })

      result = ImportViewBuilder.view_model(tool, %{})

      # Check prompting summary
      {_, import_section} = result.stack |> Enum.find(fn {type, _} -> type == :import_section end)

      {_, summary_assigns} =
        import_section.stack |> Enum.find(fn {type, _} -> type == :prompting_summary end)

      assert summary_assigns.error_count == 2
      assert summary_assigns.new_paper_count == 0

      # Should have details button to view errors
      assert summary_assigns.details_button != nil

      # Should NOT have Continue button since no new papers
      assert summary_assigns.buttons == []
    end
  end

  describe "edge cases and error handling" do
    test "handles tool with invalid ID gracefully" do
      # This should be caught by the database constraint, but let's test error handling
      # Non-existent ID
      tool = %{id: 99_999}

      assert_raise FunctionClauseError, fn ->
        ImportViewBuilder.view_model(tool, %{})
      end
    end

    test "handles complex scenarios with multiple reference files" do
      # Create multiple reference files
      ref_file_1 =
        Core.Factories.insert!(:paper_reference_file, %{
          file:
            Core.Factories.build(:content_file, %{
              name: "file1.ris",
              ref: "http://example.com/file1.ris"
            })
        })

      ref_file_2 =
        Core.Factories.insert!(:paper_reference_file, %{
          file:
            Core.Factories.build(:content_file, %{
              name: "file2.ris",
              ref: "http://example.com/file2.ris"
            })
        })

      # Create tool with multiple reference files
      tool =
        Core.Factories.insert!(:zircon_screening_tool, %{
          reference_files: [ref_file_1, ref_file_2]
        })

      result = ImportViewBuilder.view_model(tool, %{})

      # Should get the most recent uploaded file
      assert result.active_filename in ["file1.ris", "file2.ris"]

      assert result.active_file_url in [
               "http://example.com/file1.ris",
               "http://example.com/file2.ris"
             ]
    end
  end
end
