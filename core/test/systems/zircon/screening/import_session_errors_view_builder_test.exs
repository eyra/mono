defmodule Systems.Zircon.Screening.ImportSessionErrorsViewBuilderTest do
  use ExUnit.Case
  alias Systems.Zircon.Screening.ImportSessionErrorsViewBuilder

  describe "view_model/2" do
    test "extracts errors from entries and sets up pagination" do
      entries = [
        %{
          "status" => "error",
          "error" => %{"line" => 1, "error" => "Parse error", "content" => "TY  - INVALID"}
        },
        %{"status" => "new", "title" => "Valid Paper"},
        %{
          "status" => "error",
          "error" => %{"line" => 5, "error" => "Missing field", "content" => "AU  -"}
        }
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{}

      result = ImportSessionErrorsViewBuilder.view_model(session, assigns)

      assert length(result.errors) == 2
      assert result.filtered_errors |> Enum.count() == 2
      assert result.error_count == 2
      assert result.page_count == 1
      assert result.page_index == 0
      # Only 2 errors, threshold is >10
      assert result.show_action_bar? == false
    end

    test "enables action bar when more than 10 errors" do
      # Create 11 errors
      entries =
        Enum.map(1..11, fn i ->
          %{
            "status" => "error",
            "error" => %{"line" => i, "error" => "Error #{i}", "content" => "Content #{i}"}
          }
        end)

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{}

      result = ImportSessionErrorsViewBuilder.view_model(session, assigns)

      assert length(result.errors) == 11
      assert result.show_action_bar? == true
      # 11 errors / 10 per page = 2 pages
      assert result.page_count == 2
    end

    test "handles pagination correctly" do
      # Create 15 errors
      entries =
        Enum.map(1..15, fn i ->
          %{
            "status" => "error",
            "error" => %{"line" => i, "error" => "Error #{i}", "content" => "Content #{i}"}
          }
        end)

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      # Test first page
      assigns = %{page_index: 0}
      result = ImportSessionErrorsViewBuilder.view_model(session, assigns)

      assert length(result.page_errors) == 10
      assert result.page_index == 0
      assert result.page_count == 2

      # Test second page
      assigns = %{page_index: 1}
      result = ImportSessionErrorsViewBuilder.view_model(session, assigns)

      assert length(result.page_errors) == 5
      assert result.page_index == 1
    end

    test "filters errors based on query" do
      entries = [
        %{
          "status" => "error",
          "error" => %{"line" => 1, "error" => "Parse error", "content" => "TY  - INVALID"}
        },
        %{
          "status" => "error",
          "error" => %{"line" => 5, "error" => "Missing author", "content" => "AU  -"}
        },
        %{
          "status" => "error",
          "error" => %{"line" => 10, "error" => "Invalid format", "content" => "DO  - bad"}
        }
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      # Search for "author"
      assigns = %{query: ["author"]}
      result = ImportSessionErrorsViewBuilder.view_model(session, assigns)

      assert result.filtered_errors |> Enum.count() == 1
      assert result.error_count == 1
      assert hd(result.filtered_errors).error =~ "author"
    end

    test "filters with multiple query terms (AND logic)" do
      entries = [
        %{
          "status" => "error",
          "error" => %{
            "line" => 1,
            "error" => "Parse error in format",
            "content" => "TY  - INVALID"
          }
        },
        %{
          "status" => "error",
          "error" => %{"line" => 5, "error" => "Missing author", "content" => "AU  -"}
        },
        %{
          "status" => "error",
          "error" => %{"line" => 10, "error" => "Invalid format", "content" => "DO  - bad"}
        }
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      # Search for "error" AND "format" - both must be present
      assigns = %{query: ["error", "format"]}
      result = ImportSessionErrorsViewBuilder.view_model(session, assigns)

      # Only the first error has both "error" and "format" in the text
      assert result.filtered_errors |> Enum.count() == 1
      assert result.error_count == 1
    end

    test "search is case-insensitive" do
      entries = [
        %{
          "status" => "error",
          "error" => %{"line" => 1, "error" => "PARSE ERROR", "content" => "content"}
        }
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{query: ["parse"]}
      result = ImportSessionErrorsViewBuilder.view_model(session, assigns)

      assert result.filtered_errors |> Enum.count() == 1
    end

    test "handles empty query correctly" do
      entries = [
        %{
          "status" => "error",
          "error" => %{"line" => 1, "error" => "Error 1", "content" => "Content 1"}
        },
        %{
          "status" => "error",
          "error" => %{"line" => 2, "error" => "Error 2", "content" => "Content 2"}
        }
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      # Test with nil query
      assigns = %{query: nil}
      result = ImportSessionErrorsViewBuilder.view_model(session, assigns)
      assert result.filtered_errors |> Enum.count() == 2

      # Test with empty list query
      assigns = %{query: []}
      result = ImportSessionErrorsViewBuilder.view_model(session, assigns)
      assert result.filtered_errors |> Enum.count() == 2
    end

    test "includes search bar component" do
      session = %{
        entries: [],
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{}

      result = ImportSessionErrorsViewBuilder.view_model(session, assigns)

      assert result.search_bar != nil
      assert result.search_bar.implementation == Frameworks.Pixel.SearchBar
      assert result.search_bar.options[:id] == "errors_search_bar"
      assert result.search_bar.options[:debounce] == "200"
    end

    test "handles different error formats" do
      entries = [
        # Format 1: line/error
        %{
          "status" => "error",
          "error" => %{"line" => 1, "error" => "Error 1", "content" => "C1"}
        },
        # Format 2: line_number/message
        %{
          "status" => "error",
          "error" => %{"line_number" => 2, "message" => "Error 2", "content" => "C2"}
        },
        # Format 3: atom keys
        %{"status" => "error", "error" => %{line: 3, error: "Error 3", content: "C3"}}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{}

      result = ImportSessionErrorsViewBuilder.view_model(session, assigns)

      assert length(result.errors) == 3
      # All errors should be properly extracted regardless of format
    end

    test "filters only error entries, ignoring new and existing" do
      entries = [
        %{
          "status" => "error",
          "error" => %{"line" => 1, "error" => "Error", "content" => "Content"}
        },
        %{"status" => "new", "title" => "New Paper"},
        %{"status" => "existing", "title" => "Existing Paper"},
        %{
          "status" => "error",
          "error" => %{"line" => 5, "error" => "Another error", "content" => "Content"}
        }
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{}

      result = ImportSessionErrorsViewBuilder.view_model(session, assigns)

      assert length(result.errors) == 2

      assert Enum.all?(result.errors, fn error ->
               # Errors should have line and error fields after processing
               Map.has_key?(error, :line) || Map.has_key?(error, :line_number)
             end)
    end
  end

  describe "edge cases" do
    test "handles empty entries list" do
      session = %{
        entries: [],
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{}

      result = ImportSessionErrorsViewBuilder.view_model(session, assigns)

      assert result.errors == []
      assert result.filtered_errors == []
      assert result.page_errors == []
      assert result.error_count == 0
      # Minimum 1 page even with no data
      assert result.page_count == 1
      assert result.show_action_bar? == false
    end

    test "handles nil or missing error content gracefully" do
      entries = [
        %{"status" => "error", "error" => %{"line" => 1, "error" => "Error", "content" => nil}},
        %{"status" => "error", "error" => %{"line" => 2, "error" => nil, "content" => "Content"}},
        # Missing both error and content
        %{"status" => "error", "error" => %{"line" => 3}}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{query: ["error"]}

      # Should not crash when filtering with nil values
      result = ImportSessionErrorsViewBuilder.view_model(session, assigns)

      assert is_list(result.filtered_errors)
      # First error should match the query "error"
      assert length(result.filtered_errors) >= 1
    end

    test "calculates correct page count for exact page boundary" do
      # Exactly 20 errors (2 full pages)
      entries =
        Enum.map(1..20, fn i ->
          %{
            "status" => "error",
            "error" => %{"line" => i, "error" => "Error #{i}", "content" => "Content"}
          }
        end)

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{}

      result = ImportSessionErrorsViewBuilder.view_model(session, assigns)

      assert result.page_count == 2
      assert result.error_count == 20
    end
  end
end
