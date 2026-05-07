defmodule Systems.Zircon.Screening.RISErrorContentTest do
  use CoreWeb.ConnCase, async: false

  alias Systems.Paper
  alias Systems.Paper.RISEntryError

  describe "RIS error content display" do
    test "error table should display the actual line content from RIS file" do
      # Create an error structure similar to what comes from the parser
      error_from_parser = %{
        "line_number" => 5,
        "message" =>
          "Unsupported reference type. Supported types are: JOUR, JFULL, ABST, INPR, CPAPER, THES",
        "type" => "validation_error",
        # This is what we want to see
        "line_content" => "TY  - BOOK"
      }

      # Convert to RISEntryError
      error = RISEntryError.from_map(error_from_parser)

      # The content should be preserved
      assert error.content == "TY  - BOOK"
    end

    test "RISEntryError.from_map should preserve line_content" do
      # Create an error structure with line_content
      error_map = %{
        "line_number" => 5,
        "message" =>
          "Unsupported reference type. Supported types are: JOUR, JFULL, ABST, INPR, CPAPER, THES",
        "type" => "validation_error",
        "line_content" => "TY  - BOOK"
      }

      error = RISEntryError.from_map(error_map)

      # The content should be preserved
      assert error.line == 5

      assert error.message ==
               "Unsupported reference type. Supported types are: JOUR, JFULL, ABST, INPR, CPAPER, THES"

      assert error.content == "TY  - BOOK"
    end

    test "RIS parser should include line content in error structures" do
      # Sample RIS content with an unsupported type
      ris_content = """
      TY  - BOOK
      T1  - Test Book Title
      AU  - Test Author
      PY  - 2024
      ER  -
      """

      references = Paper.RISParser.parse_content(ris_content)

      # Find the error reference
      error_ref =
        Enum.find(references, fn
          {:error, _} -> true
          _ -> false
        end)

      assert {:error, {error_info, _raw}} = error_ref

      # The error should have line_content field
      assert error_info.line_number == 1
      assert error_info.message =~ "Unsupported reference type"
      # This is what we need to add!
      assert error_info.line_content == "TY  - BOOK"
    end
  end
end
