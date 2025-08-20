defmodule Systems.Zircon.Screening.ImportSessionViewBuilderTest do
  use ExUnit.Case
  alias Systems.Zircon.Screening.ImportSessionViewBuilder

  describe "view_model/2 for :waiting phase" do
    test "returns processing_status block with starting message and spinner" do
      session = %{status: :activated, phase: :waiting}
      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      assert %{stack: [{:processing_status, block_assigns}]} = result
      assert block_assigns.show_spinner == true
    end
  end

  describe "view_model/2 for :parsing phase" do
    test "returns processing_status block with processing message and spinner" do
      session = %{status: :activated, phase: :parsing}
      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      assert %{stack: [{:processing_status, block_assigns}]} = result
      assert block_assigns.show_spinner == true
    end
  end

  describe "view_model/2 for :importing phase" do
    test "returns processing_status block with importing message and spinner" do
      session = %{status: :activated, phase: :importing}
      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      assert %{stack: [{:processing_status, block_assigns}]} = result
      assert block_assigns.show_spinner == true
    end
  end

  describe "view_model/2 for :prompting phase" do
    test "shows both errors and new papers when both are present" do
      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: [
          %{"status" => "new", "title" => "Paper 1", "authors" => ["Author 1"]},
          %{"status" => "existing", "title" => "Paper 2", "authors" => ["Author 2"]},
          %{"status" => "error", "error" => "Parse error 1"}
        ],
        errors: []
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      assert %{stack: stack} = result
      # Both errors and new papers blocks
      assert length(stack) == 2

      # Check that errors block is first
      {errors_type, errors_assigns} = Enum.at(stack, 0)
      assert errors_type == :prompting_errors
      assert errors_assigns.count == 1

      # Check that new papers block is second
      {papers_type, papers_assigns} = Enum.at(stack, 1)
      assert papers_type == :prompting_new_papers
      assert papers_assigns.count == 1

      assert result.has_errors == true
    end

    test "handles missing parsed_references gracefully" do
      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      assert %{stack: stack} = result
      # When entries is missing, should show empty block directly in stack
      assert [{:prompting_empty, _}] = stack
    end

    test "handles missing errors gracefully" do
      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: []
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      # When no errors and no papers, should show empty block
      assert %{stack: [{:prompting_empty, _empty_assigns}]} = result
    end

    test "shows new papers when entries contain new papers" do
      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: [
          %{"status" => "new", "title" => "Paper 1", "authors" => ["Author 1"]}
        ],
        errors: []
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      # Should have new papers block directly in stack
      {_, papers_assigns} =
        result.stack |> Enum.find(fn {type, _} -> type == :prompting_new_papers end)

      assert papers_assigns.count == 1
    end
  end

  describe "error and paper counting" do
    test "counts errors correctly when >10 errors" do
      errors = Enum.map(1..11, fn i -> %{"status" => "error", "error" => "Error #{i}"} end)

      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: errors,
        errors: []
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      {_, errors_assigns} =
        result.stack |> Enum.find(fn {type, _} -> type == :prompting_errors end)

      assert errors_assigns.count == 11
    end

    test "counts errors correctly when <=10 errors" do
      errors = Enum.map(1..10, fn i -> %{"status" => "error", "error" => "Error #{i}"} end)

      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: errors,
        errors: []
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      {_, errors_assigns} =
        result.stack |> Enum.find(fn {type, _} -> type == :prompting_errors end)

      assert errors_assigns.count == 10
    end

    test "counts new papers correctly when >10 new papers" do
      new_papers =
        Enum.map(1..11, fn i ->
          %{"status" => "new", "title" => "Paper #{i}", "authors" => ["Author #{i}"]}
        end)

      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: new_papers,
        errors: []
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      {_, papers_assigns} =
        result.stack |> Enum.find(fn {type, _} -> type == :prompting_new_papers end)

      assert papers_assigns.count == 11
    end

    test "counts new papers correctly when <=10 new papers" do
      new_papers =
        Enum.map(1..10, fn i ->
          %{"status" => "new", "title" => "Paper #{i}", "authors" => ["Author #{i}"]}
        end)

      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: new_papers,
        errors: []
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      {_, papers_assigns} =
        result.stack |> Enum.find(fn {type, _} -> type == :prompting_new_papers end)

      assert papers_assigns.count == 10
    end
  end

  describe "prompting phase view model structure" do
    test "returns has_errors flag when has new papers" do
      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: [%{"status" => "new", "title" => "Paper 1"}],
        errors: []
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      # Prompting phase doesn't include buttons - they're handled by parent ImportView
      assert %{stack: [{:prompting_new_papers, _}], has_errors: false} = result
    end

    test "returns empty block when no new papers" do
      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: [%{"status" => "existing", "title" => "Paper 1"}],
        errors: []
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      assert %{stack: [{:prompting_empty, _}], has_errors: false} = result
    end

    test "returns empty block when no entries" do
      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: [],
        errors: []
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      assert %{stack: [{:prompting_empty, _}], has_errors: false} = result
    end
  end

  describe "paper filtering logic" do
    test "shows new papers block when has new papers (no errors)" do
      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: [
          %{"status" => "new", "title" => "New Paper 1"},
          %{"status" => "existing", "title" => "Existing Paper 1"},
          %{"status" => "new", "title" => "New Paper 2"}
        ],
        errors: []
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      # Should have new papers block directly in stack
      {_, papers_assigns} =
        result.stack |> Enum.find(fn {type, _} -> type == :prompting_new_papers end)

      assert papers_assigns.count == 2
      assert result.has_errors == false
    end

    test "shows both errors and new papers when both are present" do
      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: [
          %{"status" => "new", "title" => "New Paper 1"},
          %{"status" => "existing", "title" => "Existing Paper 1"},
          %{"status" => "error", "error" => "Parse error for this entry"},
          %{"status" => "new", "title" => "New Paper 2"}
        ],
        errors: []
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      # Should show both errors and new papers blocks
      assert length(result.stack) == 2

      # Errors block first
      {errors_type, errors_assigns} = Enum.at(result.stack, 0)
      assert errors_type == :prompting_errors
      assert errors_assigns.count == 1

      # New papers block second
      {papers_type, papers_assigns} = Enum.at(result.stack, 1)
      assert papers_type == :prompting_new_papers
      assert papers_assigns.count == 2

      assert result.has_errors == true
    end
  end

  describe "view_model/2 for :processing phase" do
    test "returns processing_status block with processing message and spinner" do
      session = %{status: :activated, phase: :processing}
      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      assert %{stack: [{:processing_status, block_assigns}]} = result
      assert block_assigns.show_spinner == true
    end
  end

  describe "view_model/2 for failed status" do
    test "returns failed block with default message when no errors provided" do
      session = %{status: :failed, errors: [], reference_file: %{file: %{name: "test.ris"}}}
      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      assert %{stack: [{:failed, block_assigns}]} = result
      assert block_assigns.message != nil
      assert result.filename == "test.ris"
    end

    test "returns failed block with specific error message" do
      session = %{
        status: :failed,
        errors: ["Connection timeout", "Parse error occurred"],
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      assert %{stack: [{:failed, block_assigns}]} = result
      # Should use the last error message
      assert block_assigns.message == "Parse error occurred"
      assert result.filename == "test.ris"
    end
  end

  describe "view_model/2 for succeeded status" do
    test "returns succeeded block with success message" do
      session = %{status: :succeeded, reference_file: %{file: %{name: "test.ris"}}}
      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      assert %{stack: [{:succeeded, block_assigns}]} = result
      assert block_assigns.message != nil
      assert result.filename == "test.ris"
    end
  end

  describe "view_model/2 for aborted status" do
    test "returns aborted block with aborted message" do
      session = %{status: :aborted, reference_file: %{file: %{name: "test.ris"}}}
      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      assert %{stack: [{:aborted, block_assigns}]} = result
      assert block_assigns.message != nil
      assert result.filename == "test.ris"
    end
  end

  describe "filename handling" do
    test "adds filename when reference file exists" do
      session = %{
        status: :activated,
        phase: :waiting,
        reference_file: %{file: %{name: "important.ris"}}
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      assert result.filename == "important.ris"
    end

    test "does not add filename when reference file is missing" do
      session = %{status: :activated, phase: :waiting}
      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      refute Map.has_key?(result, :filename)
    end

    test "does not add filename when file name is missing" do
      session = %{
        status: :activated,
        phase: :waiting,
        reference_file: %{file: %{}}
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      refute Map.has_key?(result, :filename)
    end
  end

  describe "edge cases and error handling" do
    test "displays both multiple error entries and new papers" do
      # Error entries (e.g. from unsupported TY fields) should be shown in errors block
      # When there are errors AND new papers, both blocks should be shown
      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: [
          %{
            "status" => "error",
            "error" =>
              "Unsupported reference type 'BOOK'. Supported types: JOUR, JFULL, ABST, INPR, CPAPER, THES"
          },
          %{
            "status" => "error",
            "error" =>
              "Unsupported reference type 'CONF'. Supported types: JOUR, JFULL, ABST, INPR, CPAPER, THES"
          },
          %{"status" => "new", "title" => "Valid Paper", "doi" => "10.1234/test"}
        ],
        # Session-level errors are empty
        errors: []
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      # Should have both errors and papers blocks
      assert length(result.stack) == 2

      # Check that error block exists and contains the entry errors
      {errors_type, errors_assigns} = Enum.at(result.stack, 0)
      assert errors_type == :prompting_errors
      assert errors_assigns.count == 2

      # Check that new papers block exists
      {papers_type, papers_assigns} = Enum.at(result.stack, 1)
      assert papers_type == :prompting_new_papers
      assert papers_assigns.count == 1

      assert result.has_errors == true
    end

    test "handles session with nil values" do
      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: nil,
        errors: nil
      }

      assigns = %{}

      result = ImportSessionViewBuilder.view_model(session, assigns)

      assert %{stack: stack} = result
      # With nil values, should show empty block
      assert [{:prompting_empty, _}] = stack
    end

    test "handles unknown phase with fallback" do
      session = %{status: :activated, phase: :unknown_phase}
      assigns = %{}

      # The fallback case should handle unknown phases
      result = ImportSessionViewBuilder.view_model(session, assigns)

      assert %{stack: [{:processing_status, block_assigns}]} = result
      assert block_assigns.show_spinner == true
    end
  end
end
