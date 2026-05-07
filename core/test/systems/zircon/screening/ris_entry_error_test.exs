defmodule Systems.Zircon.Screening.RISEntryErrorTest do
  use ExUnit.Case

  alias Systems.Paper.RISEntryError

  describe "ris_entry_error handling" do
    test "handles error structure with line_number and message fields" do
      # This is the actual error structure from the production error
      error_data = %{
        "line_number" => 12,
        "message" =>
          "Unsupported reference type 'BOOK'. Supported types are: JOUR, JFULL, ABST, INPR, CPAPER, THES",
        "type" => "validation_error"
      }

      # Convert to RISEntryError
      error = RISEntryError.from_map(error_data)

      assert error.line == 12

      assert error.message ==
               "Unsupported reference type 'BOOK'. Supported types are: JOUR, JFULL, ABST, INPR, CPAPER, THES"
    end

    test "RISEntryError handles new field names (line/message)" do
      error_data = %{
        "line" => 10,
        "message" => "Invalid DOI format"
      }

      error = RISEntryError.from_map(error_data)

      assert error.line == 10
      assert error.message == "Invalid DOI format"
    end
  end
end
