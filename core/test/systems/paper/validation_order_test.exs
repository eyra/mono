defmodule Systems.Paper.ValidationOrderTest do
  @moduledoc """
  Test that validation checks happen in the correct order and return
  appropriate error messages for different file types.
  """

  use Core.DataCase
  alias Systems.Paper.RISParserStream

  describe "validation order and messages" do
    test "PNG file gets binary file message" do
      # PNG header
      png_content =
        <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A>> <> String.duplicate("A", 1000)

      stream = Stream.map([png_content], & &1)

      results = RISParserStream.parse_stream_with_validation(stream) |> Enum.to_list()

      assert [{:error, {error_map, _}}] = results

      assert error_map.message ==
               "This appears to be an image or document file. Please upload a RIS bibliography file instead."
    end

    test "PDF file gets binary file message" do
      # PDF header
      pdf_content = "%PDF-1.4\n" <> String.duplicate("Content", 100)
      stream = Stream.map([pdf_content], & &1)

      results = RISParserStream.parse_stream_with_validation(stream) |> Enum.to_list()

      assert [{:error, {error_map, _}}] = results

      assert error_map.message ==
               "This appears to be an image or document file. Please upload a RIS bibliography file instead."
    end

    test "Invalid UTF-8 (not binary file) gets encoding message" do
      # Invalid UTF-8 that doesn't match binary patterns
      # Using bytes that are invalid UTF-8 but not at position 0-7
      invalid_utf8 = "HELLO" <> <<0xFF, 0xFE, 0xFD>> <> "Some text"
      stream = Stream.map([invalid_utf8], & &1)

      results = RISParserStream.parse_stream_with_validation(stream) |> Enum.to_list()

      assert [{:error, {error_map, _}}] = results

      assert error_map.message ==
               "This doesn't appear to be a valid RIS file. Please upload a RIS bibliography file instead."
    end

    test "Valid text but not RIS gets RIS format message" do
      plain_text =
        "This is just a plain text file.\nNo RIS formatting here.\nJust regular content."

      stream = Stream.map([plain_text], & &1)

      results = RISParserStream.parse_stream_with_validation(stream) |> Enum.to_list()

      assert [{:error, {error_map, _}}] = results

      assert error_map.message ==
               "This doesn't appear to be a valid RIS file. Please upload a RIS bibliography file instead."
    end

    test "Valid RIS file passes all checks" do
      valid_ris = """
      TY  - JOUR
      TI  - Test Article
      AU  - Smith, John
      PY  - 2023
      ER  -
      """

      stream = Stream.map([valid_ris], & &1)

      results = RISParserStream.parse_stream_with_validation(stream) |> Enum.to_list()

      assert [{:ok, {attrs, _}}] = results
      assert attrs.title == "Test Article"
    end
  end
end
