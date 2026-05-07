defmodule Systems.Paper.RISParserTest do
  use ExUnit.Case, async: true

  alias Systems.Paper.RISParser

  describe "parse_content/1" do
    test "parses valid RIS content successfully" do
      ris_content = """
      TY  - JOUR
      T1  - Test Article Title
      AU  - Smith, John
      PY  - 2024
      DO  - 10.1234/test.2024.001
      AB  - This is a test abstract.
      KW  - testing
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 1
      assert [{:ok, {attrs, raw}}] = references

      assert attrs.type == "JOUR"
      assert attrs.title == "Test Article Title"
      assert attrs.authors == "Smith, John"
      assert attrs.year == "2024"
      assert attrs.doi == "10.1234/test.2024.001"
      assert attrs.abstract == "This is a test abstract."
      assert attrs.keywords == "testing"
      assert String.contains?(raw, "Test Article Title")
    end

    test "parses multiple references correctly" do
      ris_content = """
      TY  - JOUR
      T1  - First Article
      DO  - 10.1234/first
      ER  -

      TY  - ABST
      T1  - Second Article
      DO  - 10.1234/second
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 2

      [{:ok, {attrs1, _}}, {:ok, {attrs2, _}}] = references
      assert attrs1.title == "First Article"
      assert attrs1.doi == "10.1234/first"
      assert attrs2.title == "Second Article"
      assert attrs2.doi == "10.1234/second"
    end

    test "handles empty RIS content" do
      references = RISParser.parse_content("")
      assert references == []
    end

    test "handles references without ER tag" do
      ris_content = """
      TY  - JOUR
      T1  - Article Without End
      DO  - 10.1234/test
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 1
      [{:ok, {attrs, _}}] = references
      assert attrs.title == "Article Without End"
    end

    test "handles invalid RIS content" do
      ris_content = """
      T1  - Test Article Without Type
      AU  - Smith, John
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 1
      [{:error, {error_message, raw}}] = references

      assert error_message.message ==
               "This file is missing required reference type information. Please upload a RIS bibliography file instead."

      assert error_message.type == :validation_error
      assert error_message.line_number == 1

      assert String.contains?(raw, "Test Article Without Type")
    end

    test "accepts all supported reference types" do
      supported_types = ["JOUR", "JFULL", "ABST", "INPR", "CPAPER", "THES"]

      for type <- supported_types do
        ris_content = """
        TY  - #{type}
        T1  - Test Article for #{type}
        ER  -
        """

        references = RISParser.parse_content(ris_content)
        assert length(references) == 1
        [{:ok, {attrs, _raw}}] = references
        assert attrs.type == type
      end
    end

    test "rejects unsupported reference types" do
      ris_content = """
      TY  - BOOK
      T1  - Unsupported Book Reference
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 1
      [{:error, {error_message, _raw}}] = references
      assert error_message.message =~ "Unsupported reference type"
      assert error_message.type == :validation_error
      assert error_message.message =~ "JOUR, JFULL, ABST, INPR, CPAPER, THES"
    end

    test "sample.ris contains unsupported types that should generate errors" do
      # Test that the actual sample.ris file used in tests contains unsupported types
      test_file_path =
        Path.join([
          __DIR__,
          "..",
          "..",
          "..",
          "test",
          "systems",
          "zircon",
          "screening",
          "test_data",
          "sample.ris"
        ])

      {:ok, content} = File.read(test_file_path)

      references = RISParser.parse_content(content)

      # Should have 1 valid entry (JOUR) and 2 errors (BOOK, CONF)
      valid_refs =
        Enum.filter(references, fn
          {:ok, _} -> true
          _ -> false
        end)

      error_refs =
        Enum.filter(references, fn
          {:error, _} -> true
          _ -> false
        end)

      assert length(valid_refs) == 1
      assert length(error_refs) == 2

      # Check the valid entry
      [{:ok, {jour_entry, _raw}}] = valid_refs
      assert jour_entry.type == "JOUR"
      assert jour_entry.title == "Test Paper for Upload"

      # Check the errors
      [{:error, {book_error, _raw1}}, {:error, {conf_error, _raw2}}] = error_refs
      assert book_error.message =~ "Unsupported reference type"
      assert book_error.type == :validation_error
      assert conf_error.message =~ "Unsupported reference type"
    end

    test "handles different title tags (TI vs T1)" do
      # Test with TI tag
      ris_content_ti = """
      TY  - JOUR
      TI  - Title Using TI Tag
      ER  -
      """

      references_ti = RISParser.parse_content(ris_content_ti)
      [{:ok, {attrs_ti, _}}] = references_ti
      assert attrs_ti.title == "Title Using TI Tag"

      # Test with T1 tag
      ris_content_t1 = """
      TY  - JOUR
      T1  - Title Using T1 Tag
      ER  -
      """

      references_t1 = RISParser.parse_content(ris_content_t1)
      [{:ok, {attrs_t1, _}}] = references_t1
      assert attrs_t1.title == "Title Using T1 Tag"
    end

    test "skips unsupported tags without failing" do
      # Test that unsupported tags are ignored and don't cause errors
      ris_content = """
      TY  - JOUR
      T1  - Valid Article Title
      AU  - Smith, John
      XX  - This is an unsupported tag
      PY  - 2024
      ZZ  - Another unsupported tag
      AB  - This is the abstract
      ER  -
      """

      references = RISParser.parse_content(ris_content)
      assert length(references) == 1

      [{:ok, {attrs, _raw}}] = references

      # Verify that valid fields are parsed
      assert attrs.title == "Valid Article Title"
      assert attrs.authors == "Smith, John"
      assert attrs.year == "2024"
      assert attrs.abstract == "This is the abstract"

      # Verify that unsupported tags are not in the attributes
      refute Map.has_key?(attrs, :xx)
      refute Map.has_key?(attrs, :zz)
    end

    test "handles different DOI tags (DOI, DO, DI)" do
      doi_tags = [
        {"DOI", "10.1234/doi.tag"},
        {"DO", "10.1234/do.tag"},
        {"DI", "10.1234/di.tag"}
      ]

      for {tag, expected_doi} <- doi_tags do
        ris_content = """
        TY  - JOUR
        T1  - Test Article
        #{tag}  - #{expected_doi}
        ER  -
        """

        references = RISParser.parse_content(ris_content)
        [{:ok, {attrs, _}}] = references
        assert Map.get(attrs, :doi) == expected_doi
      end
    end

    test "handles multiple author tags" do
      ris_content = """
      TY  - JOUR
      T1  - Article with Multiple Authors
      AU  - Primary Author
      A1  - Another Primary
      A2  - Secondary Author
      A3  - Tertiary Author
      ER  -
      """

      references = RISParser.parse_content(ris_content)
      [{:ok, {attrs, _}}] = references

      # Parser takes the last author value
      assert attrs.authors == "Tertiary Author"
    end

    test "handles subtitle field (T2)" do
      ris_content = """
      TY  - JOUR
      T1  - Main Title
      T2  - Subtitle of the Article
      ER  -
      """

      references = RISParser.parse_content(ris_content)
      [{:ok, {attrs, _}}] = references
      assert attrs.subtitle == "Subtitle of the Article"
    end

    test "handles abstract and keywords" do
      ris_content = """
      TY  - JOUR
      T1  - Article with Abstract
      AB  - This is the abstract of the article with some detailed information.
      KW  - keyword1
      KW  - keyword2
      ER  -
      """

      references = RISParser.parse_content(ris_content)
      [{:ok, {attrs, _}}] = references

      assert attrs.abstract ==
               "This is the abstract of the article with some detailed information."

      # Takes last keyword
      assert attrs.keywords == "keyword2"
    end

    test "handles invalid RIS line formats" do
      ris_content = """
      TY  - JOUR
      T1  - Valid Title
      This is not a valid RIS line
      InvalidTag - Value
      X1 - Value for invalid tag
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      # With strict parsing, invalid lines cause an error
      assert length(references) == 1
      [{:error, {error, _raw}}] = references
      assert error.type == :parse_error
      assert error.line_number == 3
      assert error.message =~ "invalid formatting"
    end

    test "handles empty values" do
      ris_content = """
      TY  - JOUR
      T1  -
      DO  -
      AU  -
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 1
      [{:ok, {attrs, _}}] = references
      assert attrs.title == ""
      assert attrs.doi == ""
    end

    test "handles special characters in values" do
      ris_content = """
      TY  - JOUR
      T1  - Title with "quotes" and 'apostrophes' & special chars: <test>
      AU  - O'Brien, Mary-Jane
      AB  - Abstract with unicode: €, α, β, γ, 中文
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 1
      [{:ok, {attrs, _}}] = references
      assert attrs.title == "Title with \"quotes\" and 'apostrophes' & special chars: <test>"
      assert attrs.authors == "O'Brien, Mary-Jane"
      assert attrs.abstract =~ "€, α, β, γ, 中文"
    end

    test "handles extra spaces in tag formatting" do
      ris_content = """
      TY  -    JOUR
      T1  -    Title with Extra Spaces
      DO  -10.1234/test
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 1
      [{:ok, {attrs, _}}] = references
      assert attrs.title == "Title with Extra Spaces"
      assert Map.get(attrs, :doi) == "10.1234/test"
    end

    test "handles year (PY) and date (DA) fields" do
      ris_content = """
      TY  - JOUR
      T1  - Article with Dates
      PY  - 2024
      DA  - 2024/03/15
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 1
      [{:ok, {attrs, _}}] = references
      assert attrs.year == "2024"
      assert attrs.date == "2024/03/15"
    end

    test "handles journal abbreviation field" do
      ris_content = """
      TY  - JOUR
      T1  - Journal Article
      J2  - J. Test. Sci.
      ER  -
      """

      references = RISParser.parse_content(ris_content)

      assert length(references) == 1
      [{:ok, {attrs, _}}] = references
      assert attrs.abbreviated_journal == "J. Test. Sci."
    end
  end
end
