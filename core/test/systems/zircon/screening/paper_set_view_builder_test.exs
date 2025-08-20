defmodule Systems.Zircon.Screening.PaperSetViewBuilderTest do
  use Core.DataCase
  alias Systems.Zircon.Screening.PaperSetViewBuilder

  describe "view_model/2 basic functionality" do
    test "creates view model with default values" do
      paper_set = %{papers: []}
      assigns = %{}

      result = PaperSetViewBuilder.view_model(paper_set, assigns)

      assert result.page_index == 0
      assert result.page_count == 0
      assert result.page == []
      assert result.show_action_bar? == false
      assert result.search_bar != nil
    end

    test "creates view model with papers" do
      papers = create_test_papers(5)
      paper_set = %{papers: papers}
      assigns = %{}

      result = PaperSetViewBuilder.view_model(paper_set, assigns)

      assert result.page_index == 0
      # 5 papers = 1 page
      assert result.page_count == 1
      assert length(result.page) == 5
      assert result.show_action_bar? == false
    end

    test "respects page_index from assigns" do
      papers = create_test_papers(25)
      paper_set = %{papers: papers}
      assigns = %{page_index: 1}

      result = PaperSetViewBuilder.view_model(paper_set, assigns)

      assert result.page_index == 1
      # Second page
      assert length(result.page) == 10
    end

    test "respects query from assigns" do
      papers = [
        %{title: "Machine Learning", authors: ["Smith"], abstract: "AI research", doi: "10.1/ml"},
        %{
          title: "Deep Learning",
          authors: ["Jones"],
          abstract: "Neural networks",
          doi: "10.1/dl"
        },
        %{title: "Statistics", authors: ["Brown"], abstract: "Math stuff", doi: "10.1/stat"}
      ]

      paper_set = %{papers: papers}
      assigns = %{query: ["learning"]}

      result = PaperSetViewBuilder.view_model(paper_set, assigns)

      # Only papers with "learning" in title
      assert length(result.page) == 2
    end
  end

  describe "pagination logic" do
    test "calculates correct page_count for exact multiple of page_size" do
      papers = create_test_papers(20)
      paper_set = %{papers: papers}

      result = PaperSetViewBuilder.view_model(paper_set, %{})

      assert result.page_count == 2
    end

    test "calculates correct page_count for non-multiple of page_size" do
      papers = create_test_papers(25)
      paper_set = %{papers: papers}

      result = PaperSetViewBuilder.view_model(paper_set, %{})

      # ceil(25/10) = 3
      assert result.page_count == 3
    end

    test "returns empty page for out-of-bounds page_index" do
      papers = create_test_papers(15)
      paper_set = %{papers: papers}
      # Way beyond available pages
      assigns = %{page_index: 5}

      result = PaperSetViewBuilder.view_model(paper_set, assigns)

      assert result.page == []
      assert result.page_index == 5
    end

    test "correctly slices papers for each page" do
      papers = create_test_papers(25)
      paper_set = %{papers: papers}

      # First page
      result_page_0 = PaperSetViewBuilder.view_model(paper_set, %{page_index: 0})
      assert length(result_page_0.page) == 10
      assert hd(result_page_0.page).title == "Paper 1"

      # Second page
      result_page_1 = PaperSetViewBuilder.view_model(paper_set, %{page_index: 1})
      assert length(result_page_1.page) == 10
      assert hd(result_page_1.page).title == "Paper 11"

      # Third page (partial)
      result_page_2 = PaperSetViewBuilder.view_model(paper_set, %{page_index: 2})
      assert length(result_page_2.page) == 5
      assert hd(result_page_2.page).title == "Paper 21"
    end
  end

  describe "action bar display logic" do
    test "shows action bar when more than 10 papers" do
      papers = create_test_papers(11)
      paper_set = %{papers: papers}

      result = PaperSetViewBuilder.view_model(paper_set, %{})

      assert result.show_action_bar? == true
    end

    test "hides action bar when exactly 10 papers" do
      papers = create_test_papers(10)
      paper_set = %{papers: papers}

      result = PaperSetViewBuilder.view_model(paper_set, %{})

      assert result.show_action_bar? == false
    end

    test "hides action bar when less than 10 papers" do
      papers = create_test_papers(5)
      paper_set = %{papers: papers}

      result = PaperSetViewBuilder.view_model(paper_set, %{})

      assert result.show_action_bar? == false
    end

    test "action bar based on filtered papers, not total papers" do
      papers = create_test_papers(15)
      paper_set = %{papers: papers}
      # Query that filters down to less than 10 papers
      # Will match "Paper 1" and "Paper 10-19"
      assigns = %{query: ["Paper 1"]}

      result = PaperSetViewBuilder.view_model(paper_set, assigns)

      # Action bar is based on filtered results (matches only "Paper 1", "Paper 10-15")
      # That's 7 papers total (Paper 1, Paper 10, Paper 11, Paper 12, Paper 13, Paper 14, Paper 15)
      assert result.show_action_bar? == false
    end
  end

  describe "filter_papers/2" do
    test "returns all papers when query is nil" do
      papers = create_test_papers(5)

      result = PaperSetViewBuilder.filter_papers(papers, nil)

      assert result == papers
    end

    test "returns all papers when query is empty list" do
      papers = create_test_papers(5)

      result = PaperSetViewBuilder.filter_papers(papers, [])

      assert result == papers
    end

    test "filters papers by title" do
      papers = [
        %{title: "Machine Learning", authors: [], abstract: "", doi: ""},
        %{title: "Deep Learning", authors: [], abstract: "", doi: ""},
        %{title: "Statistics", authors: [], abstract: "", doi: ""}
      ]

      result = PaperSetViewBuilder.filter_papers(papers, ["learning"])

      assert length(result) == 2
      assert Enum.all?(result, fn p -> String.contains?(String.downcase(p.title), "learning") end)
    end

    test "filters papers by authors" do
      papers = [
        %{title: "Paper 1", authors: ["John Smith", "Jane Doe"], abstract: "", doi: ""},
        %{title: "Paper 2", authors: ["Bob Johnson"], abstract: "", doi: ""},
        %{title: "Paper 3", authors: ["Alice Smith"], abstract: "", doi: ""}
      ]

      result = PaperSetViewBuilder.filter_papers(papers, ["smith"])

      assert length(result) == 2
      assert Enum.any?(result, fn p -> p.title == "Paper 1" end)
      assert Enum.any?(result, fn p -> p.title == "Paper 3" end)
    end

    test "does not search in abstract field (only visible fields)" do
      papers = [
        %{title: "Paper 1", authors: [], abstract: "Study on neural networks", doi: ""},
        %{title: "Paper 2", authors: [], abstract: "Research on databases", doi: ""},
        %{title: "Networks Paper", authors: [], abstract: "Analysis of something", doi: ""}
      ]

      result = PaperSetViewBuilder.filter_papers(papers, ["networks"])

      # Should only find the paper with "networks" in the title (visible field)
      assert length(result) == 1
      assert Enum.any?(result, fn p -> p.title == "Networks Paper" end)
    end

    test "filters papers by DOI" do
      papers = [
        %{title: "Paper 1", authors: [], abstract: "", doi: "10.1234/abc"},
        %{title: "Paper 2", authors: [], abstract: "", doi: "10.5678/def"},
        %{title: "Paper 3", authors: [], abstract: "", doi: "10.1234/xyz"}
      ]

      result = PaperSetViewBuilder.filter_papers(papers, ["1234"])

      assert length(result) == 2
      assert Enum.any?(result, fn p -> p.title == "Paper 1" end)
      assert Enum.any?(result, fn p -> p.title == "Paper 3" end)
    end

    test "supports multiple search phrases (AND logic)" do
      papers = [
        %{title: "Machine Learning Statistics", authors: [], abstract: "", doi: ""},
        %{title: "Deep Learning", authors: [], abstract: "", doi: ""},
        %{title: "Statistics", authors: [], abstract: "", doi: ""},
        %{title: "Statistics Databases", authors: [], abstract: "", doi: ""}
      ]

      result = PaperSetViewBuilder.filter_papers(papers, ["statistics", "databases"])

      # Only papers with both "statistics" AND "databases" should match
      assert length(result) == 1
      assert Enum.any?(result, fn p -> p.title == "Statistics Databases" end)
    end

    test "case-insensitive search" do
      papers = [
        %{title: "MACHINE LEARNING", authors: [], abstract: "", doi: ""},
        %{title: "machine learning", authors: [], abstract: "", doi: ""},
        %{title: "Machine Learning", authors: [], abstract: "", doi: ""}
      ]

      result = PaperSetViewBuilder.filter_papers(papers, ["MACHINE"])
      assert length(result) == 3

      result = PaperSetViewBuilder.filter_papers(papers, ["machine"])
      assert length(result) == 3

      result = PaperSetViewBuilder.filter_papers(papers, ["Machine"])
      assert length(result) == 3
    end

    test "handles nil fields gracefully" do
      papers = [
        %{title: nil, authors: nil, abstract: nil, doi: nil},
        %{title: "Paper", authors: nil, abstract: nil, doi: nil},
        %{title: nil, authors: ["Author"], abstract: nil, doi: nil}
      ]

      # Should not crash
      result = PaperSetViewBuilder.filter_papers(papers, ["paper"])

      assert length(result) == 1
      assert hd(result).title == "Paper"
    end

    test "handles empty strings in fields" do
      papers = [
        %{title: "", authors: [], abstract: "", doi: ""},
        %{title: "Paper", authors: [""], abstract: "", doi: ""}
      ]

      result = PaperSetViewBuilder.filter_papers(papers, ["paper"])

      assert length(result) == 1
      assert hd(result).title == "Paper"
    end
  end

  describe "search bar configuration" do
    test "creates search bar with correct configuration" do
      paper_set = %{papers: []}

      result = PaperSetViewBuilder.view_model(paper_set, %{})

      assert result.search_bar.implementation == Frameworks.Pixel.SearchBar
      assert result.search_bar.options[:id] == "search_bar"
      assert result.search_bar.options[:query_string] == ""
      assert result.search_bar.options[:placeholder] == "Search papers..."
      assert result.search_bar.options[:debounce] == "200"
    end
  end

  describe "edge cases and error handling" do
    test "handles empty paper set" do
      paper_set = %{papers: []}

      result = PaperSetViewBuilder.view_model(paper_set, %{})

      assert result.page == []
      assert result.page_count == 0
      assert result.show_action_bar? == false
    end

    test "handles very large page_index" do
      papers = create_test_papers(5)
      paper_set = %{papers: papers}
      assigns = %{page_index: 1000}

      result = PaperSetViewBuilder.view_model(paper_set, assigns)

      assert result.page == []
      assert result.page_index == 1000
    end

    test "handles negative page_index" do
      papers = create_test_papers(15)
      paper_set = %{papers: papers}
      assigns = %{page_index: -1}

      result = PaperSetViewBuilder.view_model(paper_set, assigns)

      # Negative index is preserved in result but treated as 0 for slicing
      assert result.page_index == -1
      # Should return first page
      assert length(result.page) == 10
      assert hd(result.page).title == "Paper 1"
    end

    test "handles special characters in search query" do
      papers = [
        %{title: "C++ Programming", authors: [], abstract: "", doi: ""},
        %{title: "C# Development", authors: [], abstract: "", doi: ""},
        %{title: "Regular Expressions (.*)", authors: [], abstract: "", doi: ""}
      ]

      paper_set = %{papers: papers}

      # Should handle special regex characters as literals
      result = PaperSetViewBuilder.view_model(paper_set, %{query: ["c++"]})
      assert length(result.page) == 1

      result = PaperSetViewBuilder.view_model(paper_set, %{query: ["(.*)"]})
      assert length(result.page) == 1
    end
  end

  # Helper functions

  defp create_test_papers(count) do
    Enum.map(1..count, fn i ->
      %{
        title: "Paper #{i}",
        authors: ["Author #{i}"],
        abstract: "Abstract for paper #{i}",
        doi: "10.1234/paper#{i}"
      }
    end)
  end
end
