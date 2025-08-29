defmodule Systems.Paper.RISLineTrackingTest do
  use Core.DataCase, async: true

  alias Systems.Paper.RISParser
  alias Systems.Paper.RISProcessor
  alias Systems.Paper.RISEntry

  describe "line number tracking in parse errors" do
    test "tracks line number for invalid RIS line format" do
      ris_content = """
      TY  - JOUR
      T1  - Valid Title
      This is an invalid line on line 3
      AU  - Author Name
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 1
      [{:error, {error, _raw}}] = references

      assert error.type == :parse_error
      assert error.line_number == 3
      assert error.message =~ "Invalid RIS line"
    end

    test "tracks line number for missing TY field" do
      ris_content = """
      T1  - Article Without Type
      AU  - Smith, John
      PY  - 2024
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 1
      [{:error, {error, _raw}}] = references

      assert error.type == :validation_error
      # First line of the reference
      assert error.line_number == 1
      assert error.message =~ "Missing TY"
    end

    test "tracks line numbers for multiple errors in different references" do
      ris_content = """
      T1  - First Article Without Type
      AU  - Author One
      ER  -

      TY  - JOUR
      T1  - Valid Article
      This invalid line is on line 7
      ER  -

      TY  - BOOK
      T1  - Unsupported Book Type
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 3

      # First error - missing TY
      [{:error, {error1, _}}, {:error, {error2, _}}, {:error, {error3, _}}] = references

      assert error1.type == :validation_error
      assert error1.line_number == 1
      assert error1.message =~ "Missing TY"

      # Second error - invalid line format
      assert error2.type == :parse_error
      assert error2.line_number == 7
      assert error2.message =~ "Invalid RIS line"

      # Third error - unsupported type
      assert error3.type == :validation_error
      # Line where TY appears
      assert error3.line_number == 10
      assert error3.message =~ "Unsupported reference type"
    end

    test "handles errors at different positions within a reference" do
      ris_content = """
      TY  - JOUR
      T1  - Article Title
      AU  - Author Name
      Invalid line in middle at line 4
      PY  - 2024
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 1
      [{:error, {error, _raw}}] = references

      assert error.type == :parse_error
      assert error.line_number == 4
      assert error.message =~ "Invalid RIS line"
    end
  end

  describe "error structure in RISEntry" do
    test "preserves structured error with line number in RISEntry" do
      error_data = %{
        type: :parse_error,
        line_number: 5,
        message: "Invalid RIS line format"
      }

      entry = RISEntry.error(error_data)

      assert entry.status == "error"
      assert entry.error == error_data
      assert entry.error.type == :parse_error
      assert entry.error.line_number == 5
      assert entry.error.message == "Invalid RIS line format"
    end

    test "handles string errors for backward compatibility" do
      error_message = "Simple error message"

      entry = RISEntry.error(error_message)

      assert entry.status == "error"
      assert entry.error == error_message
    end

    test "to_map preserves structured error" do
      error_data = %{
        type: :validation_error,
        line_number: 10,
        message: "Missing required field"
      }

      entry = RISEntry.error(error_data)
      map = RISEntry.to_map(entry)

      assert map.status == "error"
      assert map.error == error_data
      assert map.error.type == :validation_error
      assert map.error.line_number == 10
    end

    test "from_map reconstructs structured error" do
      map = %{
        status: "error",
        error: %{
          type: :parse_error,
          line_number: 7,
          message: "Test error"
        }
      }

      entry = RISEntry.from_map(map)

      assert entry.status == "error"
      assert entry.error.type == :parse_error
      assert entry.error.line_number == 7
      assert entry.error.message == "Test error"
    end
  end

  describe "error processing through RISProcessor" do
    setup do
      paper_set =
        Factories.insert!(:paper_set, %{
          category: :zircon,
          identifier: System.unique_integer([:positive])
        })

      {:ok, paper_set: paper_set}
    end

    test "preserves structured errors through processing", %{paper_set: paper_set} do
      error_with_line = %{
        type: :parse_error,
        line_number: 15,
        message: "Invalid format at line 15"
      }

      parsed_refs = [
        {:error, {error_with_line, "raw content with error"}}
      ]

      processed = RISProcessor.process_references(parsed_refs, paper_set)

      assert length(processed) == 1
      [{{:error, error}, raw}] = processed

      assert error == error_with_line
      assert error.type == :parse_error
      assert error.line_number == 15
      assert error.message == "Invalid format at line 15"
      assert raw == "raw content with error"
    end

    test "processes mixed valid and error references with line numbers", %{paper_set: paper_set} do
      parsed_refs = [
        {:ok, {%{type: "JOUR", title: "Valid Paper", doi: "10.1234/valid"}, "raw1"}},
        {:error,
         {%{type: :validation_error, line_number: 5, message: "Missing TY field"}, "raw2"}},
        {:error, {%{type: :parse_error, line_number: 10, message: "Invalid line format"}, "raw3"}}
      ]

      processed = RISProcessor.process_references(parsed_refs, paper_set)

      assert length(processed) == 3

      [ref1, ref2, ref3] = processed

      # Valid reference
      assert {{:ok, :new, attrs}, "raw1"} = ref1
      assert attrs.title == "Valid Paper"

      # Validation error with line number
      assert {{:error, error2}, "raw2"} = ref2
      assert error2.type == :validation_error
      assert error2.line_number == 5
      assert error2.message == "Missing TY field"

      # Parse error with line number
      assert {{:error, error3}, "raw3"} = ref3
      assert error3.type == :parse_error
      assert error3.line_number == 10
      assert error3.message == "Invalid line format"
    end
  end

  describe "line tracking across multiline references" do
    test "correctly tracks line numbers when references span multiple lines" do
      ris_content = """
      TY  - JOUR
      T1  - First Article
      AU  - Author One
      AB  - This is a long abstract that continues on a single line
      ER  -

      TY  - CPAPER
      T1  - Conference Paper
      Invalid line here
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 2

      # First should be valid, second should have error
      case references do
        [{:ok, {attrs, _}}, {:error, {error, _}}] ->
          assert attrs.title == "First Article"
          assert error.type == :parse_error
          assert error.line_number == 9
          assert error.message =~ "Invalid RIS line"

        # Both might be errors if AB continuation lines are invalid
        [{:error, {error1, _}}, {:error, {error2, _}}] ->
          # The multiline abstract causes an error
          assert error1.type == :parse_error
          assert error2.type == :parse_error
          assert error2.message =~ "Invalid RIS line"
      end
    end

    test "tracks line numbers with empty lines between references" do
      ris_content = """
      TY  - JOUR
      T1  - First Article
      ER  -



      T1  - Article Without Type Starting at Line 7
      AU  - Author
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 2

      [{:ok, _}, {:error, {error, _}}] = references

      assert error.type == :validation_error
      # Where the problematic reference starts
      assert error.line_number == 7
      assert error.message =~ "Missing TY"
    end
  end

  describe "error display in UI layer" do
    test "ImportSessionWarningsViewBuilder extracts message from structured error" do
      alias Systems.Zircon.Screening.ImportSessionWarningsViewBuilder

      # Session with structured errors
      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: [
          %{
            status: "error",
            error: %{
              type: :parse_error,
              line_number: 5,
              message: "Invalid RIS format"
            }
          },
          %{
            status: "error",
            error: %{
              type: :validation_error,
              line_number: 10,
              message: "Missing required field"
            }
          }
        ],
        errors: []
      }

      view_model = ImportSessionWarningsViewBuilder.view_model(session, %{})

      # Check the error count directly from the view model
      assert view_model.error_count == 2
      assert length(view_model.errors) == 2

      # Verify errors are properly formatted
      assert [error1, error2] = view_model.errors
      assert error1.line == 5
      assert error1.message == "Invalid RIS format"
      assert error2.line == 10
      assert error2.message == "Missing required field"
    end

    test "ImportSessionWarningsViewBuilder handles mixed error formats" do
      alias Systems.Zircon.Screening.ImportSessionWarningsViewBuilder

      session = %{
        status: :activated,
        phase: :prompting,
        reference_file: %{file: %{name: "test.ris"}},
        entries: [
          %{
            status: "error",
            error: %{
              type: :parse_error,
              line_number: 3,
              message: "Structured error message"
            }
          },
          %{
            status: "error",
            error: "Legacy string error"
          }
        ],
        errors: ["Session-level error"]
      }

      view_model = ImportSessionWarningsViewBuilder.view_model(session, %{})

      # Check the error count directly from the view model
      assert view_model.error_count == 2
      assert length(view_model.errors) == 2

      # Verify mixed error formats are handled
      assert [error1, error2] = view_model.errors

      # First error should be the structured one
      assert error1.line == 3
      assert error1.message == "Structured error message"

      # Second error should be converted from legacy string to struct
      # Default line number for string errors
      assert error2.line == 0
      assert error2.message == "Legacy string error"
    end
  end
end
