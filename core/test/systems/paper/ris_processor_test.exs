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
end
