defmodule Systems.Paper.RISValidatorTest do
  use Core.DataCase
  alias Systems.Paper.RISValidator

  describe "validate_content/1" do
    test "accepts valid RIS content" do
      valid_ris = """
      TY  - JOUR
      TI  - Test Article
      AU  - Smith, John
      PY  - 2023
      ER  -
      """

      assert {:ok, ^valid_ris} = RISValidator.validate_content(valid_ris)
    end

    test "rejects content exceeding maximum size" do
      # Create content larger than 10MB
      large_content = String.duplicate("A", 11_000_000)

      assert {:error, message} = RISValidator.validate_content(large_content)
      assert message =~ "The file is too large"
    end

    test "rejects binary files - JPEG" do
      # JPEG header
      jpeg_content = <<0xFF, 0xD8, 0xFF, 0xE0>> <> String.duplicate("A", 1000)

      assert {:error, message} = RISValidator.validate_content(jpeg_content)
      assert message =~ "image or document file"
    end

    test "rejects binary files - PNG" do
      # PNG header
      png_content =
        <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A>> <> String.duplicate("B", 1000)

      assert {:error, message} = RISValidator.validate_content(png_content)
      assert message =~ "image or document file"
    end

    test "rejects binary files - PDF" do
      # PDF header
      pdf_content = "%PDF-1.4" <> <<0x00, 0x00, 0x00, 0x00>> <> String.duplicate("C", 1000)

      assert {:error, message} = RISValidator.validate_content(pdf_content)
      assert message =~ "image or document file"
    end

    test "rejects files with invalid text encoding" do
      # Invalid UTF-8 sequences
      invalid_utf8 = <<0xFF, 0xFE, 0xFD>> <> "Some text"

      assert {:error, message} = RISValidator.validate_content(invalid_utf8)
      assert message =~ "invalid characters"
    end

    test "rejects files without RIS header" do
      no_header = """
      This is not a RIS file
      Just some random text
      Without proper formatting
      """

      assert {:error, message} = RISValidator.validate_content(no_header)
      assert message =~ "doesn't appear to be a RIS file"
    end

    test "rejects files without ER end markers" do
      no_end = """
      TY  - JOUR
      TI  - Test Article
      AU  - Smith, John
      PY  - 2023
      """

      assert {:error, message} = RISValidator.validate_content(no_end)
      assert message =~ "appears to be incomplete"
    end

    test "rejects files with invalid RIS structure" do
      invalid_structure = """
      TY  - JOUR
      This line doesn't follow RIS format
      Neither does this one
      Random text here
      ER  -
      """

      assert {:error, message} = RISValidator.validate_content(invalid_structure)
      assert message =~ "valid bibliography file"
    end

    test "accepts RIS files with continuation lines" do
      with_continuation = """
      TY  - JOUR
      TI  - A very long title that
        continues on the next line
      AU  - Smith, John
      AB  - This is an abstract that spans
        multiple lines and uses
        continuation formatting
      ER  -
      """

      assert {:ok, _} = RISValidator.validate_content(with_continuation)
    end

    test "accepts RIS files with multiple records" do
      multiple_records = """
      TY  - JOUR
      TI  - First Article
      AU  - Smith, John
      ER  -

      TY  - BOOK
      TI  - Second Item
      AU  - Doe, Jane
      ER  -
      """

      assert {:ok, _} = RISValidator.validate_content(multiple_records)
    end

    test "rejects files with too many null bytes" do
      # Create content with many null bytes (binary indicator)
      null_heavy = String.duplicate(<<0>>, 100) <> "TY  - JOUR" <> String.duplicate(<<0>>, 100)

      assert {:error, message} = RISValidator.validate_content(null_heavy)
      assert message =~ "image or document file"
    end
  end

  describe "validate_with_timeout/2" do
    test "validates content within timeout" do
      valid_ris = """
      TY  - JOUR
      TI  - Test Article
      ER  -
      """

      assert {:ok, _} = RISValidator.validate_with_timeout(valid_ris, 1000)
    end

    test "times out on slow validation" do
      # This test is tricky because we need validation to take time
      # In practice, large malformed files would cause this
      # For testing, we'll use a very short timeout

      valid_ris = """
      TY  - JOUR
      TI  - Test Article
      ER  -
      """

      # With 0 timeout, it should timeout
      assert {:error, message} = RISValidator.validate_with_timeout(valid_ris, 0)
      assert message =~ "timed out"
    end
  end

  describe "real-world edge cases" do
    test "handles image file disguised as RIS" do
      # Simulate a real image file (first 1KB of a JPEG)
      fake_ris =
        <<0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x01,
          0x00,
          0x48>> <>
          String.duplicate(<<0xFF, 0xD9>>, 500)

      assert {:error, message} = RISValidator.validate_content(fake_ris)
      assert message =~ "image or document file"
    end

    test "handles extremely long lines (potential DOS)" do
      # Create a file with an extremely long line
      long_line = "TY  - " <> String.duplicate("A", 1_000_000)
      malicious = long_line <> "\nER  -\n"

      # Should reject based on structure or size
      assert {:error, _} = RISValidator.validate_content(malicious)
    end

    test "handles mixed valid and invalid content" do
      # Start with valid RIS, then add binary data
      mixed =
        """
        TY  - JOUR
        TI  - Valid Start
        """ <>
          <<0xFF, 0xD8, 0xFF>> <>
          """
          AU  - Author
          ER  -
          """

      # Should detect the binary content
      assert {:error, _} = RISValidator.validate_content(mixed)
    end
  end
end
