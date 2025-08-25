defmodule Systems.Paper.RISProcessorTest do
  use Core.DataCase

  alias Systems.Paper.RISProcessor

  describe "process_references/2" do
    setup do
      paper_set =
        Factories.insert!(:paper_set, %{
          category: :zircon,
          identifier: System.unique_integer([:positive])
        })

      # Create existing paper with DOI
      existing_paper_doi =
        Factories.insert!(:paper, %{
          doi: "10.1234/existing.doi",
          title: "Existing Paper with DOI",
          sets: [paper_set]
        })

      # Create existing paper with title only
      existing_paper_title =
        Factories.insert!(:paper, %{
          doi: nil,
          title: "Existing Paper Title Only",
          sets: [paper_set]
        })

      {:ok,
       paper_set: paper_set,
       existing_paper_doi: existing_paper_doi,
       existing_paper_title: existing_paper_title}
    end

    test "processes new paper successfully", %{paper_set: paper_set} do
      parsed_refs = [
        {:ok,
         {%{
            type: "JOUR",
            title: "New Paper Title",
            doi: "10.1234/new.paper",
            authors: "Test Author",
            year: "2024"
          }, "raw content"}}
      ]

      processed = RISProcessor.process_references(parsed_refs, paper_set)

      assert length(processed) == 1
      [{{:ok, :new, attrs}, raw}] = processed

      assert attrs.title == "New Paper Title"
      assert attrs.doi == "10.1234/new.paper"
      assert attrs.authors == ["Test Author"]
      assert raw == "raw content"
    end

    test "detects existing paper by DOI", %{
      paper_set: paper_set,
      existing_paper_doi: existing_paper_doi
    } do
      parsed_refs = [
        {:ok,
         {%{
            type: "JOUR",
            title: "Different Title",
            doi: "10.1234/existing.doi"
          }, "raw content"}}
      ]

      processed = RISProcessor.process_references(parsed_refs, paper_set)

      assert length(processed) == 1
      [{{:ok, :existing, _attrs, paper_id}, _raw}] = processed
      assert paper_id == existing_paper_doi.id
    end

    test "detects existing paper by title", %{
      paper_set: paper_set,
      existing_paper_title: existing_paper_title
    } do
      parsed_refs = [
        {:ok,
         {%{
            type: "JOUR",
            title: "Existing Paper Title Only"
          }, "raw content"}}
      ]

      processed = RISProcessor.process_references(parsed_refs, paper_set)

      assert length(processed) == 1
      [{{:ok, :existing, _attrs, paper_id}, _raw}] = processed
      assert paper_id == existing_paper_title.id
    end

    test "DOI match takes precedence over title", %{
      paper_set: paper_set,
      existing_paper_doi: existing_paper_doi
    } do
      # Create another paper with same title but no DOI
      _other_paper =
        Factories.insert!(:paper, %{
          doi: nil,
          title: "Existing Paper with DOI",
          sets: [paper_set]
        })

      parsed_refs = [
        {:ok,
         {%{
            type: "JOUR",
            title: "Existing Paper with DOI",
            doi: "10.1234/existing.doi"
          }, "raw content"}}
      ]

      processed = RISProcessor.process_references(parsed_refs, paper_set)

      assert length(processed) == 1
      [{{:ok, :existing, _attrs, paper_id}, _raw}] = processed
      # Should match by DOI, not title
      assert paper_id == existing_paper_doi.id
    end

    test "processes error references correctly", %{paper_set: paper_set} do
      parsed_refs = [
        {:error, {"Missing required field", "raw error content"}}
      ]

      processed = RISProcessor.process_references(parsed_refs, paper_set)

      assert length(processed) == 1
      [{{:error, "Missing required field"}, raw}] = processed
      assert raw == "raw error content"
    end

    test "processes mixed references", %{
      paper_set: paper_set,
      existing_paper_doi: existing_paper_doi
    } do
      parsed_refs = [
        {:ok, {%{type: "JOUR", title: "New Paper", doi: "10.1234/new"}, "raw1"}},
        {:ok, {%{type: "JOUR", title: "Existing", doi: "10.1234/existing.doi"}, "raw2"}},
        {:error, {"Invalid type", "raw3"}}
      ]

      processed = RISProcessor.process_references(parsed_refs, paper_set)

      assert length(processed) == 3

      [ref1, ref2, ref3] = processed

      # New paper
      assert {{:ok, :new, attrs}, "raw1"} = ref1
      assert attrs.title == "New Paper"

      # Existing paper
      assert {{:ok, :existing, attrs, paper_id}, "raw2"} = ref2
      assert paper_id == existing_paper_doi.id
      assert attrs.title == "Existing"

      # Error
      assert {{:error, "Invalid type"}, "raw3"} = ref3
    end
  end

  describe "build_summary/1" do
    test "builds summary correctly" do
      processed_refs = [
        {{:ok, :new, %{}}, ""},
        {{:ok, :new, %{}}, ""},
        {{:ok, :existing, %{}, 123}, ""},
        {{:error, "some error"}, ""}
      ]

      summary = RISProcessor.build_summary(processed_refs)

      assert summary.total == 4
      assert summary.new == 2
      assert summary.existing == 1
      assert summary.errors == 1
    end

    test "handles empty references" do
      summary = RISProcessor.build_summary([])

      assert summary.total == 0
      assert summary.new == 0
      assert summary.existing == 0
      assert summary.errors == 0
    end
  end

  describe "format_references/1" do
    test "formats new reference correctly" do
      attrs = %{
        title: "Test Title",
        doi: "10.1234/test",
        authors: ["Test Author"],
        year: "2024"
      }

      processed_refs = [
        {{:ok, :new, attrs}, "raw content"}
      ]

      formatted = RISProcessor.format_references(processed_refs)

      assert length(formatted) == 1
      [ref] = formatted

      assert ref.status == :new
      assert ref.title == "Test Title"
      assert ref.doi == "10.1234/test"
      assert ref.raw == "raw content"
    end

    test "formats existing reference correctly" do
      attrs = %{
        title: "Existing Title",
        doi: "10.1234/existing"
      }

      processed_refs = [
        {{:ok, :existing, attrs, 123}, "raw content"}
      ]

      formatted = RISProcessor.format_references(processed_refs)

      assert length(formatted) == 1
      [ref] = formatted

      assert ref.status == :existing
      assert ref.title == "Existing Title"
      assert ref.doi == "10.1234/existing"
      assert ref.paper_id == 123
      assert ref.raw == "raw content"
    end

    test "formats error reference correctly" do
      processed_refs = [
        {{:error, "validation error"}, "invalid content"}
      ]

      formatted = RISProcessor.format_references(processed_refs)

      assert length(formatted) == 1
      [ref] = formatted

      assert ref.status == :error
      assert ref.error == "validation error"
      assert ref.raw == "invalid content"
    end
  end

  describe "same title different DOI handling" do
    setup do
      paper_set =
        Factories.insert!(:paper_set, %{
          category: :zircon,
          identifier: System.unique_integer([:positive])
        })

      {:ok, paper_set: paper_set}
    end

    test "papers with same title but different DOIs are treated as different papers", %{
      paper_set: paper_set
    } do
      # This tests the edge case where papers have identical titles but different DOIs
      # These should be considered different papers and both should be marked as new
      parsed_refs = [
        {:ok,
         {%{
            type: "JOUR",
            title: "Exercise and Diabetes",
            doi: "10.1111/j.1742-1241.2010.02581.x",
            authors: "Smith, J."
          }, "raw1"}},
        {:ok,
         {%{
            type: "JOUR",
            # Same title
            title: "Exercise and Diabetes",
            # Different DOI
            doi: "10.1016/s0733-8651(05)70231-9",
            authors: "Jones, K."
          }, "raw2"}}
      ]

      processed = RISProcessor.process_references(parsed_refs, paper_set)

      assert length(processed) == 2

      # Both should be marked as new papers (not duplicates)
      assert {{:ok, :new, %{doi: "10.1111/j.1742-1241.2010.02581.x"}}, _} = Enum.at(processed, 0)
      assert {{:ok, :new, %{doi: "10.1016/s0733-8651(05)70231-9"}}, _} = Enum.at(processed, 1)
    end

    test "papers with same title but different DOIs are inserted separately in database", %{
      paper_set: paper_set
    } do
      # First paper with title
      _first_paper =
        Factories.insert!(:paper, %{
          title: "Exercise and Diabetes",
          doi: "10.1111/j.1742-1241.2010.02581.x",
          sets: [paper_set]
        })

      # Try to process a second paper with same title but different DOI
      parsed_refs = [
        {:ok,
         {%{
            type: "JOUR",
            # Same title as existing
            title: "Exercise and Diabetes",
            # Different DOI
            doi: "10.1016/s0733-8651(05)70231-9",
            authors: "Different Author"
          }, "raw"}}
      ]

      processed = RISProcessor.process_references(parsed_refs, paper_set)

      assert length(processed) == 1

      # Should be marked as new, NOT as existing (since DOI is different)
      assert {{:ok, :new, %{doi: "10.1016/s0733-8651(05)70231-9"}}, _} = Enum.at(processed, 0)

      # Verify using Private.check_paper_exists directly
      result =
        Systems.Paper.Private.check_paper_exists(
          %{title: "Exercise and Diabetes", doi: "10.1016/s0733-8651(05)70231-9"},
          paper_set
        )

      assert result == :new, "Paper with different DOI should be considered new"
    end

    test "papers with same title but no DOI are detected as duplicates", %{paper_set: paper_set} do
      # When papers have no DOI, they should be detected as duplicates by title
      parsed_refs = [
        {:ok,
         {%{
            type: "JOUR",
            title: "Exercise and Diabetes",
            authors: "Smith, J."
            # No DOI
          }, "raw1"}},
        {:ok,
         {%{
            type: "JOUR",
            # Same title
            title: "Exercise and Diabetes",
            authors: "Jones, K."
            # No DOI
          }, "raw2"}}
      ]

      processed = RISProcessor.process_references(parsed_refs, paper_set)

      assert length(processed) == 2

      # First should be new
      assert {{:ok, :new, %{title: "Exercise and Diabetes"}}, _} = Enum.at(processed, 0)

      # Second should be error (intrinsic duplicate)
      assert {{:error, msg}, _} = Enum.at(processed, 1)
      assert is_map(msg)
      assert msg["message"] =~ "Duplicate"
    end
  end

  describe "intrinsic duplicate detection" do
    setup do
      paper_set =
        Factories.insert!(:paper_set, %{
          category: :zircon,
          identifier: System.unique_integer([:positive])
        })

      {:ok, paper_set: paper_set}
    end

    test "marks intrinsic duplicates as errors when using parser output", %{paper_set: paper_set} do
      # Use the actual parser to ensure we test with real data structure
      alias Systems.Paper.RISParser

      ris_content = """
      TY  - JOUR
      T1  - First Paper
      DOI - 10.1234/duplicate.doi
      AU  - Author One
      PY  - 2023
      ER  -

      TY  - JOUR
      T1  - Second Paper Same DOI
      DOI - 10.1234/duplicate.doi
      AU  - Author Two
      PY  - 2024
      ER  -
      """

      # Parse with actual parser to get real structure
      parsed_references = RISParser.parse_content(ris_content)

      # Process the references
      processed = RISProcessor.process_references(parsed_references, paper_set)

      assert length(processed) == 2

      # First should be new
      assert {{:ok, :new, %{doi: "10.1234/duplicate.doi"}}, _} = Enum.at(processed, 0)

      # Second should be error (intrinsic duplicate)
      assert {{:error, msg}, _} = Enum.at(processed, 1)
      assert is_map(msg)
      assert msg["message"] =~ "Duplicate"
      assert msg["content"] == "10.1234/duplicate.doi"
    end

    test "intrinsic duplicate errors have proper structure for display", %{paper_set: paper_set} do
      # This test ensures intrinsic duplicate errors have the same structure as parsing errors
      # so they can be displayed properly in ImportSessionErrorsView
      alias Systems.Paper.RISParser

      ris_content = """
      TY  - JOUR
      T1  - Duplicate Paper Title
      DOI - 10.1234/duplicate.doi
      AU  - Author One
      PY  - 2023
      ER  -

      TY  - JOUR
      T1  - Another Paper with Same DOI
      DOI - 10.1234/duplicate.doi
      AU  - Author Two
      PY  - 2024
      ER  -
      """

      parsed_references = RISParser.parse_content(ris_content)
      processed = RISProcessor.process_references(parsed_references, paper_set)

      # Get the error entry
      assert {{:error, error_msg}, _raw} = Enum.at(processed, 1)

      # The error should be a map with proper structure, not a plain string
      # This test will fail until we fix the format
      assert is_map(error_msg), "Error should be a map with line, message, and content fields"
      assert Map.has_key?(error_msg, :line) || Map.has_key?(error_msg, "line")
      assert Map.has_key?(error_msg, :message) || Map.has_key?(error_msg, "message")
      assert Map.has_key?(error_msg, :content) || Map.has_key?(error_msg, "content")

      # The error message should mention it's a duplicate
      error_text = Map.get(error_msg, :message) || Map.get(error_msg, "message")
      assert error_text =~ "Duplicate"
      # The DOI should be in the content field
      content = Map.get(error_msg, :content) || Map.get(error_msg, "content")
      assert content == "10.1234/duplicate.doi"
    end

    test "detects duplicates by title when no DOI present", %{paper_set: paper_set} do
      parsed_refs = [
        {:ok,
         {%{
            type: "JOUR",
            title: "Same Title Paper",
            authors: "Author One",
            year: "2023"
          }, "raw1"}},
        {:ok,
         {%{
            type: "JOUR",
            title: "Same Title Paper",
            authors: "Author Two",
            year: "2024"
          }, "raw2"}}
      ]

      processed = RISProcessor.process_references(parsed_refs, paper_set)

      assert length(processed) == 2

      # First should be new
      assert {{:ok, :new, %{title: "Same Title Paper"}}, _} = Enum.at(processed, 0)

      # Second should be error (intrinsic duplicate)
      assert {{:error, msg}, _} = Enum.at(processed, 1)
      assert is_map(msg)
      assert msg["message"] =~ "Duplicate"
      assert msg["content"] == "Same Title Paper"
    end

    test "different DOIs are not duplicates even with same title", %{paper_set: paper_set} do
      parsed_refs = [
        {:ok,
         {%{
            type: "JOUR",
            doi: "10.1111/paper1",
            title: "Same Title",
            authors: "Author One"
          }, "raw1"}},
        {:ok,
         {%{
            type: "JOUR",
            doi: "10.2222/paper2",
            title: "Same Title",
            authors: "Author Two"
          }, "raw2"}}
      ]

      processed = RISProcessor.process_references(parsed_refs, paper_set)

      assert length(processed) == 2

      # Both should be new (different DOIs)
      assert {{:ok, :new, %{doi: "10.1111/paper1"}}, _} = Enum.at(processed, 0)
      assert {{:ok, :new, %{doi: "10.2222/paper2"}}, _} = Enum.at(processed, 1)
    end

    test "intrinsic duplicate errors contain correct line numbers", %{paper_set: paper_set} do
      # Simulate parsed refs with line numbers as they come from the parser
      parsed_refs = [
        {:ok,
         {%{
            type: "JOUR",
            title: "First Paper",
            doi: "10.1234/duplicate",
            authors: "Author One",
            # First entry starts at line 1
            line_number: 1
          }, "TY  - JOUR\nT1  - First Paper\nDOI - 10.1234/duplicate\nER  - "}},
        {:ok,
         {%{
            type: "JOUR",
            title: "Second Paper",
            doi: "10.5678/unique",
            authors: "Author Two",
            # Second entry starts at line 8
            line_number: 8
          }, "TY  - JOUR\nT1  - Second Paper\nDOI - 10.5678/unique\nER  - "}},
        {:ok,
         {%{
            type: "JOUR",
            title: "Duplicate of First",
            # Same DOI as first entry
            doi: "10.1234/duplicate",
            authors: "Author Three",
            # Third entry starts at line 15
            line_number: 15
          }, "TY  - JOUR\nT1  - Duplicate of First\nDOI - 10.1234/duplicate\nER  - "}}
      ]

      processed = RISProcessor.process_references(parsed_refs, paper_set)

      assert length(processed) == 3

      # First should be new
      assert {{:ok, :new, _attrs1}, _} = Enum.at(processed, 0)
      # Note: line_number is not preserved in processed attrs for new/existing papers
      # It's only used for error reporting

      # Second should be new (different DOI)
      assert {{:ok, :new, _attrs2}, _} = Enum.at(processed, 1)

      # Third should be error (intrinsic duplicate)
      assert {{:error, error_msg}, raw} = Enum.at(processed, 2)
      assert is_map(error_msg)
      # Should use the actual line number from the third entry
      assert error_msg["line"] == 15
      assert error_msg["message"] =~ "Duplicate"
      # The DOI that caused the duplicate
      assert error_msg["content"] == "10.1234/duplicate"
      assert raw =~ "Duplicate of First"
    end
  end
end
