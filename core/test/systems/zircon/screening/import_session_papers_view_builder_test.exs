defmodule Systems.Zircon.Screening.ImportSessionPapersViewBuilderTest do
  use ExUnit.Case
  alias Systems.Zircon.Screening.ImportSessionPapersViewBuilder

  describe "view_model/2" do
    test "extracts new papers from entries and sets up pagination" do
      entries = [
        %{
          "status" => "new",
          "title" => "Paper 1",
          "authors" => "Smith, J.",
          "doi" => "10.1234/1"
        },
        %{"status" => "error", "error" => "Parse error"},
        %{"status" => "new", "title" => "Paper 2", "authors" => "Doe, J.", "doi" => "10.1234/2"},
        %{"status" => "duplicate", "title" => "Duplicate Paper"}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      # page_papers contains current page items, paper_count is total after filtering
      assert length(result.page_papers) == 2
      assert result.paper_count == 2
      assert result.page_count == 1
      assert result.page_index == 0
      # Only 2 papers, threshold is >10
      assert result.show_action_bar? == false
      # Don't test against translations - just verify description exists
      assert is_binary(result.description)
    end

    test "enables action bar when more than 10 papers" do
      # Create 11 new papers
      entries =
        Enum.map(1..11, fn i ->
          %{"status" => "new", "title" => "Paper #{i}", "authors" => "Author #{i}"}
        end)

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "large_import.ris"}}
      }

      assigns = %{}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      # page_papers only has current page (10 items max)
      assert length(result.page_papers) == 10
      assert result.paper_count == 11
      assert result.show_action_bar? == true
      # 11 papers / 10 per page = 2 pages
      assert result.page_count == 2
    end

    test "handles pagination correctly" do
      # Create 15 new papers
      entries =
        Enum.map(1..15, fn i ->
          %{
            "status" => "new",
            "title" => "Paper #{i}",
            "authors" => "Author #{i}",
            "doi" => "10.1234/#{i}"
          }
        end)

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      # Test first page
      assigns = %{page_index: 0}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      assert length(result.page_papers) == 10
      assert result.page_index == 0
      assert result.page_count == 2

      # Test second page
      assigns = %{page_index: 1}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      assert length(result.page_papers) == 5
      assert result.page_index == 1
    end

    test "filters papers based on query in title" do
      entries = [
        %{"status" => "new", "title" => "Machine Learning Research", "authors" => "Smith, J."},
        %{"status" => "new", "title" => "Deep Learning Applications", "authors" => "Doe, J."},
        %{"status" => "new", "title" => "Statistical Analysis", "authors" => "Johnson, K."}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      # Search for "learning"
      assigns = %{query: ["learning"]}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      assert result.paper_count == 2
      # Check that page_papers contains the right items
      assert Enum.all?(result.page_papers, fn
               %{title: title} -> title && String.downcase(title) =~ "learning"
               _ -> false
             end)
    end

    test "filters papers based on query in authors" do
      entries = [
        %{"status" => "new", "title" => "Paper 1", "authors" => "Smith, John"},
        %{"status" => "new", "title" => "Paper 2", "authors" => "Doe, Jane"},
        %{"status" => "new", "title" => "Paper 3", "authors" => "Smith, Jane"}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      # Search for "smith"
      assigns = %{query: ["smith"]}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      assert result.paper_count == 2
    end

    test "filters papers based on query in DOI" do
      entries = [
        %{"status" => "new", "title" => "Paper 1", "doi" => "10.1234/abc"},
        %{"status" => "new", "title" => "Paper 2", "doi" => "10.5678/def"},
        %{"status" => "new", "title" => "Paper 3", "doi" => "10.1234/xyz"}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      # Search for "1234"
      assigns = %{query: ["1234"]}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      assert result.paper_count == 2
    end

    test "filters with multiple query terms (AND logic)" do
      entries = [
        %{"status" => "new", "title" => "Machine Learning Research", "authors" => "Smith"},
        %{"status" => "new", "title" => "Deep Learning Methods", "authors" => "Doe"},
        %{"status" => "new", "title" => "Statistics Machine", "authors" => "Johnson"}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      # Search for "machine" AND "research" - both must be present
      assigns = %{query: ["machine", "research"]}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      # Only the first paper has both "machine" and "research"
      assert result.paper_count == 1
    end

    test "search is case-insensitive" do
      entries = [
        %{"status" => "new", "title" => "MACHINE LEARNING", "authors" => "SMITH"}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{query: ["machine"]}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      assert result.paper_count == 1

      assigns = %{query: ["smith"]}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      assert result.paper_count == 1
    end

    test "handles empty query correctly" do
      entries = [
        %{"status" => "new", "title" => "Paper 1"},
        %{"status" => "new", "title" => "Paper 2"}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      # Test with nil query
      assigns = %{query: nil}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      assert result.paper_count == 2

      # Test with empty list query
      assigns = %{query: []}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      assert result.paper_count == 2
    end

    test "includes search bar component" do
      session = %{
        entries: [],
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      assert result.search_bar != nil
      assert result.search_bar.implementation == Frameworks.Pixel.SearchBar
      assert result.search_bar.options[:id] == "papers_search_bar"
      assert result.search_bar.options[:debounce] == "200"
    end

    test "filters only new entries, ignoring errors and duplicates" do
      entries = [
        %{"status" => "new", "title" => "New Paper 1"},
        %{"status" => "error", "error" => "Parse error"},
        %{"status" => "duplicate", "title" => "Duplicate Paper"},
        %{"status" => "new", "title" => "New Paper 2"}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      assert length(result.page_papers) == 2

      assert Enum.all?(result.page_papers, fn paper ->
               paper.status == "new"
             end)
    end

    test "handles papers with atom keys vs string keys" do
      entries = [
        %{"status" => "new", "title" => "Paper 1", "authors" => "Author 1"},
        # Atom keys
        %{status: "new", title: "Paper 2", authors: "Author 2"}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{query: ["paper"]}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      # Both papers should be found regardless of key type
      assert result.paper_count == 2
    end
  end

  describe "filter parameter" do
    test "filters entries by 'duplicates' filter when specified" do
      entries = [
        %{"status" => "new", "title" => "New Paper 1"},
        %{"status" => "duplicate", "title" => "Duplicate Paper 1", "paper_id" => 123},
        %{"status" => "new", "title" => "New Paper 2"},
        %{"status" => "duplicate", "title" => "Duplicate Paper 2", "paper_id" => 124},
        %{"status" => "error", "error" => "Parse error"}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      # Test with duplicates filter
      assigns = %{}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: "duplicates"},
          assigns
        )

      # Should only show duplicates
      assert length(result.page_papers) == 2
      assert result.paper_count == 2

      assert Enum.all?(result.page_papers, fn paper ->
               paper.status == "duplicate"
             end)
    end

    test "filters entries by 'new' filter by default" do
      entries = [
        %{"status" => "new", "title" => "New Paper 1"},
        %{"status" => "duplicate", "title" => "Duplicate Paper 1"},
        %{"status" => "new", "title" => "New Paper 2"},
        %{"status" => "error", "error" => "Parse error"}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      # Test without filter (should default to "new")
      assigns = %{}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      # Should only show new papers
      assert length(result.page_papers) == 2
      assert result.paper_count == 2

      assert Enum.all?(result.page_papers, fn paper ->
               paper.status == "new"
             end)
    end

    test "shows correct papers when 0 new papers but duplicates exist" do
      # This is the key test case for the bug
      entries = [
        %{"status" => "duplicate", "title" => "Duplicate Paper 1", "paper_id" => 123},
        %{"status" => "duplicate", "title" => "Duplicate Paper 2", "paper_id" => 124},
        %{"status" => "duplicate", "title" => "Duplicate Paper 3", "paper_id" => 125},
        %{"status" => "error", "error" => "Parse error"}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      # Test with "new" filter - should show 0 papers
      assigns = %{}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      assert result.paper_count == 0
      assert result.page_papers == []

      # Test with "duplicates" filter - should show 3 papers
      assigns = %{}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: "duplicates"},
          assigns
        )

      assert result.paper_count == 3
      assert length(result.page_papers) == 3

      assert Enum.all?(result.page_papers, fn paper ->
               paper.status == "duplicate"
             end)
    end

    test "REPRODUCES BUG: filter not passed correctly shows new papers when duplicates clicked" do
      # This test reproduces the actual bug where the filter isn't being passed correctly
      # When duplicates button is clicked but filter doesn't get through, it defaults to "new"
      entries = [
        %{"status" => "duplicate", "title" => "Duplicate Paper 1", "paper_id" => 123},
        %{"status" => "duplicate", "title" => "Duplicate Paper 2", "paper_id" => 124},
        %{"status" => "duplicate", "title" => "Duplicate Paper 3", "paper_id" => 125}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      # Simulate what happens when the filter doesn't get passed through correctly
      # The ViewBuilder would receive empty assigns or assigns without filter
      # No filter in assigns!
      assigns = %{}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      # Bug behavior: defaults to "new" filter, shows 0 papers
      # This should FAIL if we want duplicates but it shows new papers (0)
      assert result.paper_count == 0, "Should show 0 papers with default 'new' filter"
      assert result.page_papers == []

      # The description would also be wrong - it would show "New papers extracted from file"
      # when it should show "Duplicates found in file"
      assert result.description =~ "New papers",
             "Description shows new papers text instead of duplicates"

      # THIS IS THE BUG: When clicking duplicates button (2nd button when 0 new papers),
      # the filter doesn't get set to "duplicates", so it defaults to "new" and shows 0 papers
    end
  end

  describe "edge cases" do
    test "handles empty entries list" do
      session = %{
        entries: [],
        reference_file: %{file: %{name: "empty.ris"}}
      }

      assigns = %{}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      assert result.page_papers == []
      assert result.paper_count == 0
      # Minimum 1 page even with no data
      assert result.page_count == 1
      assert result.show_action_bar? == false
    end

    test "handles nil or missing paper fields gracefully" do
      entries = [
        %{"status" => "new", "title" => nil, "authors" => "Smith"},
        %{"status" => "new", "title" => "Paper", "authors" => nil},
        # Missing title and authors
        %{"status" => "new", "doi" => "10.1234/test"},
        # Missing all fields
        %{"status" => "new"}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{query: ["smith"]}

      # Should not crash when filtering with nil values
      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      assert is_list(result.page_papers)
      # Only the one with "Smith" in authors
      assert result.paper_count == 1
    end

    test "calculates correct page count for exact page boundary" do
      # Exactly 20 papers (2 full pages)
      entries =
        Enum.map(1..20, fn i ->
          %{"status" => "new", "title" => "Paper #{i}", "authors" => "Author #{i}"}
        end)

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      assert result.page_count == 2
      assert result.paper_count == 20
    end

    test "does not search in abstract field (only visible fields)" do
      entries = [
        %{
          "status" => "new",
          "title" => "Machine Paper",
          "abstract" => "This paper discusses learning"
        },
        %{"status" => "new", "title" => "Paper 2", "abstract" => "Machine learning methods"},
        # No abstract
        %{"status" => "new", "title" => "Paper 3"}
      ]

      session = %{
        entries: entries,
        reference_file: %{file: %{name: "test.ris"}}
      }

      assigns = %{query: ["machine"]}

      result =
        ImportSessionPapersViewBuilder.view_model(
          %{session: session, filter: Map.get(assigns, :filter, "new")},
          assigns
        )

      # Should only find the paper with "machine" in the title (visible field)
      assert result.paper_count == 1
      assert hd(result.page_papers).title == "Machine Paper"
    end
  end
end
