defmodule Systems.Paper.RISParserStream do
  @moduledoc """
  Streaming RIS parser that processes records one at a time without loading
  the entire file into memory. Designed for handling large files with 100k+ references.
  """

  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Paper.RISValidator

  # Supported RIS reference types
  @supported_reference_types ["JOUR", "JFULL", "ABST", "INPR", "CPAPER", "THES"]

  # RIS field tags
  @end_of_reference_tag "ER"

  @doc """
  Parse a stream of RIS content, yielding parsed references one at a time.

  Returns a stream that emits {:ok, {attrs, raw}} or {:error, {error, raw}} for each reference.
  This allows processing millions of references without loading them all into memory.
  """
  def parse_stream(content_stream) do
    content_stream
    |> Stream.transform(
      # Initial accumulator: {buffer, line_number, record_count}
      fn -> {"", 1, 0} end,

      # Transform function
      fn chunk, {buffer, line_num, record_count} ->
        # Add chunk to buffer
        full_buffer = buffer <> chunk

        # Process complete records in the buffer
        {records, remaining_buffer, new_line_num} =
          extract_complete_records(full_buffer, line_num)

        # Parse and emit the complete records
        parsed_records = Enum.map(records, &parse_record/1)

        new_record_count = record_count + length(records)

        {parsed_records, {remaining_buffer, new_line_num, new_record_count}}
      end,

      # Final function - process any remaining buffer
      fn
        {"", _line_num, _record_count} ->
          {:halt, nil}

        {buffer, line_num, _record_count} ->
          # Process the last record if it exists
          lines = String.split(buffer, ~r/\r?\n/)

          if has_complete_record?(lines) do
            record = build_record(lines, line_num)
            parsed = parse_record(record)
            {[parsed], nil}
          else
            {[], nil}
          end
      end
    )
  end

  @doc """
  Validate and parse a stream with early termination on critical errors.
  Applies validation before parsing to catch binary files, encoding issues, etc.
  """
  def parse_stream_with_validation(content_stream) do
    # First chunk validation - detect binary files early
    content_stream
    # Take first chunk for validation
    |> Stream.take(1)
    |> Stream.flat_map(fn first_chunk ->
      process_validated_chunk(first_chunk, content_stream)
    end)
  end

  # Private functions

  defp process_validated_chunk(first_chunk, content_stream) do
    case validate_initial_chunk(first_chunk) do
      :ok ->
        # If valid, parse the full stream
        full_stream = Stream.concat([first_chunk], content_stream |> Stream.drop(1))
        parse_stream(full_stream)

      {:error, reason} ->
        # Return validation error as a single stream element
        create_validation_error_stream(reason)
    end
  end

  defp create_validation_error_stream(reason) do
    error_map = %{
      type: :validation_error,
      message: reason,
      line_number: 1,
      line_content: ""
    }

    Stream.iterate({:error, {error_map, ""}}, fn _ -> nil end) |> Stream.take(1)
  end

  defp extract_complete_records(buffer, line_num) do
    lines = String.split(buffer, ~r/\r?\n/, trim: false)

    # Find complete records (ending with ER tag)
    {complete_records, remaining_lines} =
      extract_records_from_lines(lines, [], [], line_num)

    # Reconstruct remaining buffer
    remaining_buffer =
      case remaining_lines do
        [] -> ""
        lines -> Enum.join(lines, "\n")
      end

    # Calculate new line number
    complete_lines_count =
      complete_records
      |> Enum.map(fn {record, _start_line} -> length(record) end)
      |> Enum.sum()

    new_line_num = line_num + complete_lines_count

    {complete_records, remaining_buffer, new_line_num}
  end

  defp extract_records_from_lines([], current_record, complete_records, _line_num) do
    # Return incomplete record as remaining lines
    {Enum.reverse(complete_records), Enum.reverse(current_record)}
  end

  defp extract_records_from_lines([line | rest], current_record, complete_records, line_num) do
    updated_record = [line | current_record]

    if String.starts_with?(line, @end_of_reference_tag <> " ") do
      # Found end of record
      record = Enum.reverse(updated_record)
      record_with_line = {record, line_num - length(record) + 1}
      extract_records_from_lines(rest, [], [record_with_line | complete_records], line_num + 1)
    else
      extract_records_from_lines(rest, updated_record, complete_records, line_num + 1)
    end
  end

  defp has_complete_record?(lines) do
    Enum.any?(lines, &String.starts_with?(&1, @end_of_reference_tag <> " "))
  end

  defp build_record(lines, start_line) do
    {lines, start_line}
  end

  defp parse_record({lines, start_line}) do
    raw = Enum.join(lines, "\n")

    # Parse the lines into attributes
    attrs =
      lines
      |> Enum.reduce(%{line_number: start_line}, fn line, acc ->
        process_parsed_line(parse_ris_line(line), acc)
      end)

    # Validate the parsed reference
    case validate_reference(attrs) do
      :ok ->
        {:ok, {attrs, raw}}

      {:error, reason} ->
        {:error, {format_error(reason, start_line, lines), raw}}
    end
  end

  defp process_parsed_line({:ok, {field, value}}, acc) do
    # Handle multi-value fields like authors
    case field do
      :authors ->
        Map.update(acc, field, [value], &(&1 ++ [value]))

      :keywords ->
        Map.update(acc, field, [value], &(&1 ++ [value]))

      _ ->
        Map.put(acc, field, value)
    end
  end

  defp process_parsed_line({:skip, _}, acc), do: acc

  defp process_parsed_line({:error, _}, acc) do
    # Continue parsing despite line errors
    acc
  end

  defp parse_ris_line(line) do
    case Regex.run(~r/^([A-Z0-9]{2,3})\s*-\s*(.*)$/, line) do
      [_, tag, value] ->
        field = tag_to_field(tag)

        if field do
          {:ok, {field, String.trim(value)}}
        else
          {:skip, tag}
        end

      _ ->
        if String.trim(line) == "" or String.starts_with?(line, " ") do
          # Empty line or continuation line
          {:skip, nil}
        else
          {:error, "Invalid line format"}
        end
    end
  end

  defp tag_to_field("TY"), do: :type
  defp tag_to_field("ER"), do: :end
  defp tag_to_field("TI"), do: :title
  defp tag_to_field("T1"), do: :title
  defp tag_to_field("T2"), do: :subtitle
  defp tag_to_field("AU"), do: :authors
  defp tag_to_field("A1"), do: :authors
  defp tag_to_field("A2"), do: :authors
  defp tag_to_field("A3"), do: :authors
  defp tag_to_field("PY"), do: :year
  defp tag_to_field("DA"), do: :date
  defp tag_to_field("DOI"), do: :doi
  defp tag_to_field("DO"), do: :doi
  defp tag_to_field("DI"), do: :doi
  defp tag_to_field("AB"), do: :abstract
  defp tag_to_field("KW"), do: :keywords
  defp tag_to_field("J2"), do: :abbreviated_journal
  defp tag_to_field(_), do: nil

  defp validate_reference(attrs) do
    type = Map.get(attrs, :type)

    cond do
      is_nil(type) ->
        {:error, dgettext("eyra-paper", "ris.error.missing_type_field")}

      type not in @supported_reference_types ->
        supported = Enum.join(@supported_reference_types, ", ")
        {:error, dgettext("eyra-paper", "ris.error.unsupported_type", supported_types: supported)}

      true ->
        :ok
    end
  end

  defp validate_initial_chunk(chunk) do
    # Quick validation of first chunk to detect binary files
    # Check binary BEFORE encoding - binary files will fail encoding check
    cond do
      RISValidator.is_binary_content?(chunk) ->
        {:error, dgettext("eyra-paper", "ris.error.binary_file_detected")}

      not String.valid?(chunk) ->
        # Invalid encoding usually means it's not a text file at all
        {:error, dgettext("eyra-paper", "ris.error.not_valid_ris_file")}

      not String.contains?(chunk, "TY  -") ->
        {:error, dgettext("eyra-paper", "ris.error.not_valid_ris_file")}

      true ->
        :ok
    end
  end

  defp format_error(message, line_number, lines) do
    first_line = List.first(lines) || ""

    %{
      type: :validation_error,
      line_number: line_number,
      message: message,
      line_content: first_line
    }
  end
end
