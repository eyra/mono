defmodule Systems.Paper.RISValidator do
  @moduledoc """
  Validates RIS files before parsing to prevent crashes from invalid files.
  """

  require Logger
  use Gettext, backend: CoreWeb.Gettext

  # Maximum time allowed for validation (30 seconds for large files)
  @validation_timeout 30_000

  # Binary patterns that indicate non-text files
  @binary_patterns [
    # Common image file headers
    # JPEG
    <<0xFF, 0xD8, 0xFF>>,
    # PNG
    <<0x89, 0x50, 0x4E, 0x47>>,
    # GIF
    <<0x47, 0x49, 0x46, 0x38>>,
    # BMP
    <<0x42, 0x4D>>,
    # Common document headers
    # PDF
    <<0x25, 0x50, 0x44, 0x46>>,
    # MS Office
    <<0xD0, 0xCF, 0x11, 0xE0>>,
    # ZIP/DOCX/XLSX
    <<0x50, 0x4B, 0x03, 0x04>>,
    # Executable headers
    # Windows EXE
    <<0x4D, 0x5A>>,
    # Linux ELF
    <<0x7F, 0x45, 0x4C, 0x46>>
  ]

  @doc """
  Validates RIS content before parsing.
  Returns {:ok, content} if valid, {:error, reason} if invalid.
  """
  def validate_content(content) when is_binary(content) do
    with :ok <- validate_size(content),
         :ok <- validate_not_binary(content),
         :ok <- validate_text_encoding(content),
         :ok <- validate_ris_format(content) do
      {:ok, content}
    end
  end

  def validate_content(_), do: {:error, dgettext("eyra-paper", "ris.error.invalid_content")}

  # Private validation functions

  defp validate_size(content) do
    size = byte_size(content)
    max_file_size = get_max_file_size()

    if size > max_file_size do
      {:error,
       dgettext("eyra-paper", "ris.error.file_too_large",
         size: format_bytes(size),
         max_size: format_bytes(max_file_size)
       )}
    else
      :ok
    end
  end

  defp get_max_file_size do
    Application.fetch_env!(:core, :paper)
    |> Keyword.fetch!(:ris_max_file_size)
  end

  defp validate_not_binary(content) do
    # Check first 1KB for binary patterns
    check_size = min(byte_size(content), 1024)
    header = binary_part(content, 0, check_size)

    if binary_file?(header) do
      {:error, dgettext("eyra-paper", "ris.error.binary_file_detected")}
    else
      :ok
    end
  end

  defp validate_text_encoding(content) do
    # Check if content is valid UTF-8 or ASCII
    # Take a sample from the beginning of the file
    sample_size = min(byte_size(content), 10_000)
    sample = binary_part(content, 0, sample_size)

    case String.valid?(sample) do
      true -> :ok
      false -> {:error, dgettext("eyra-paper", "ris.error.invalid_text_encoding")}
    end
  end

  defp validate_ris_format(content) do
    # Check for basic RIS structure
    # RIS files should have TY (type) and ER (end record) tags
    sample_size = min(byte_size(content), 50_000)
    sample = binary_part(content, 0, sample_size)

    cond do
      not String.contains?(sample, "TY  -") ->
        {:error, dgettext("eyra-paper", "ris.error.missing_ris_header")}

      not String.contains?(sample, "ER  -") ->
        {:error, dgettext("eyra-paper", "ris.error.missing_ris_end_marker")}

      not has_valid_ris_structure?(sample) ->
        {:error, dgettext("eyra-paper", "ris.error.invalid_ris_structure")}

      true ->
        :ok
    end
  end

  @doc """
  Check if content appears to be binary (not text).
  Exposed for streaming validation.
  """
  def is_binary_content?(content) when is_binary(content) do
    binary_file?(content)
  end

  defp binary_file?(header) do
    # Check for known binary file signatures AT THE BEGINNING of the file
    # File signatures should be at position 0 (or very close to it)
    has_pattern =
      Enum.any?(@binary_patterns, fn pattern ->
        # Only check first 512 bytes for binary signatures
        check_region = binary_part(header, 0, min(512, byte_size(header)))
        match_result = :binary.match(check_region, pattern)

        # Only consider it a match if pattern is found in first 8 bytes
        # (most file signatures are at position 0-4)
        case match_result do
          {position, _length} when position < 8 ->
            true

          _ ->
            false
        end
      end)

    has_nulls = has_too_many_null_bytes?(header)

    has_pattern or has_nulls
  end

  defp has_too_many_null_bytes?(content) do
    # Count null bytes in the sample
    null_count =
      content
      |> :binary.bin_to_list()
      |> Enum.count(&(&1 == 0))

    total_size = byte_size(content)
    threshold = total_size * 0.1

    # If more than 10% are null bytes, likely binary
    null_count > threshold
  end

  defp has_valid_ris_structure?(content) do
    # Basic check for RIS line structure (TAG  - VALUE)
    lines = String.split(content, ~r/\r?\n/, trim: true) |> Enum.take(100)

    # Count valid RIS format lines
    valid_lines =
      Enum.count(lines, fn line ->
        # RIS lines should match: "XX  - content" where XX is 2-3 uppercase letters/numbers
        # Or be continuation lines (starting with spaces)
        # Or be empty
        String.match?(line, ~r/^[A-Z0-9]{2,3}\s+-\s+/) or
          String.match?(line, ~r/^\s+/) or
          String.trim(line) == ""
      end)

    # At least 50% of lines should match RIS format
    valid_lines >= length(lines) * 0.5
  end

  defp format_bytes(bytes) when bytes < 1024, do: "#{bytes} bytes"
  defp format_bytes(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_bytes(bytes), do: "#{Float.round(bytes / 1_048_576, 1)} MB"

  @doc """
  Validates RIS content with a timeout to prevent hanging on malformed files.
  """
  def validate_with_timeout(content, timeout \\ @validation_timeout) do
    task = Task.async(fn -> validate_content(content) end)

    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, result} ->
        result

      nil ->
        {:error, dgettext("eyra-paper", "ris.error.validation_timeout")}
    end
  end
end
