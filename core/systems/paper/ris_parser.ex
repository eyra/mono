defmodule Systems.Paper.RISParser do
  @moduledoc """
  Pure module for parsing RIS file content.

  Contains no side effects, database queries, or state management.
  Simply parses RIS format into structured data.
  """

  require Logger
  use Gettext, backend: CoreWeb.Gettext

  # Supported RIS reference types
  @supported_reference_types ["JOUR", "JFULL", "ABST", "INPR", "CPAPER", "THES"]

  # RIS field tags
  @type_of_reference_tag "TY"
  @end_of_reference_tag "ER"

  # Title tags
  @title_tag "TI"
  @primary_title_tag "T1"
  @secondary_title_tag "T2"

  # Date tags
  @year_tag "PY"
  @date_tag "DA"

  # Journal tags
  @abbreviated_journal_tag "J2"

  # Author tags
  @author_tag "AU"
  @primary_author_tag "A1"
  @secondary_author_tag "A2"
  @tertiary_author_tag "A3"
  @quaternary_author_tag "A4"
  @quinary_author_tag "A5"
  @website_editor_tag "A6"

  # DOI tags
  @doi_tag "DOI"
  @do_tag "DO"
  @di_tag "DI"

  # Other tags
  @abstract_tag "AB"
  @keyword_tag "KW"

  @field_mapping %{
    @type_of_reference_tag => :type,
    @end_of_reference_tag => :end,
    @doi_tag => :doi,
    @do_tag => :doi,
    @di_tag => :doi,
    @title_tag => :title,
    @primary_title_tag => :title,
    @secondary_title_tag => :subtitle,
    @year_tag => :year,
    @date_tag => :date,
    @abbreviated_journal_tag => :abbreviated_journal,
    @author_tag => :authors,
    @primary_author_tag => :authors,
    @secondary_author_tag => :authors,
    @tertiary_author_tag => :authors,
    @quaternary_author_tag => :authors,
    @quinary_author_tag => :authors,
    @website_editor_tag => :authors,
    @abstract_tag => :abstract,
    @keyword_tag => :keywords
  }

  # Maximum number of lines to process (supports ~100,000 papers with ~15 lines each)
  @max_lines 1_500_000

  @doc """
  Parse RIS content into structured data.

  Returns a list of parsed references:
  Each reference includes the raw RIS text for that reference.
  """
  def parse_content(ris_content) when is_binary(ris_content) do
    lines =
      ris_content
      |> String.split(~r{(\r\n|\r|\n)})
      # Limit number of lines processed
      |> Enum.take(@max_lines)
      # Add line numbers starting from 1
      |> Enum.with_index(1)
      |> Enum.reject(fn {line, _} -> line == "" end)

    # Log warning if we hit the line limit
    if length(lines) >= @max_lines do
      Logger.warning(
        "RIS file exceeded maximum line limit of #{@max_lines}. File may be truncated."
      )
    end

    lines
    |> chunk_references()
    |> Enum.map(&parse_reference/1)
  end

  # Private functions

  defp chunk_references(lines_with_numbers) do
    chunk_fun = fn {line, line_num}, acc ->
      if String.starts_with?(line, @end_of_reference_tag) do
        {:cont, Enum.reverse([{line, line_num} | acc]), []}
      else
        {:cont, [{line, line_num} | acc]}
      end
    end

    after_func = fn
      [] -> {:cont, []}
      acc -> {:cont, Enum.reverse(acc), []}
    end

    lines_with_numbers
    |> Enum.chunk_while([], chunk_fun, after_func)
    |> Enum.reject(&Enum.empty?/1)
  end

  defp parse_reference(ris_lines_with_numbers) do
    raw = extract_raw_text(ris_lines_with_numbers)
    first_line_num = get_first_line_number(ris_lines_with_numbers)
    parsed_results = parse_all_lines(ris_lines_with_numbers)

    case check_for_parse_errors(parsed_results, ris_lines_with_numbers, raw) do
      {:error, _} = error ->
        error

      :ok ->
        build_and_validate_reference(parsed_results, first_line_num, raw, ris_lines_with_numbers)
    end
  end

  defp extract_raw_text(ris_lines_with_numbers) do
    ris_lines_with_numbers
    |> Enum.map_join("\n", fn {line, _} -> line end)
  end

  defp get_first_line_number(ris_lines_with_numbers) do
    case ris_lines_with_numbers do
      [{_, num} | _] -> num
      [] -> 0
    end
  end

  defp parse_all_lines(ris_lines_with_numbers) do
    Enum.map(ris_lines_with_numbers, fn {line, line_num} ->
      {parse_ris_line(line), line_num}
    end)
  end

  defp check_for_parse_errors(parsed_results, ris_lines_with_numbers, raw) do
    parse_errors = extract_parse_errors(parsed_results, ris_lines_with_numbers)

    if Enum.empty?(parse_errors) do
      :ok
    else
      first_error = List.first(parse_errors)
      {:error, {first_error, raw}}
    end
  end

  defp extract_parse_errors(parsed_results, ris_lines_with_numbers) do
    parsed_results
    |> Enum.filter(fn
      {{:error, _}, _} -> true
      _ -> false
    end)
    |> Enum.map(fn {{:error, msg}, line_num} ->
      line_content = find_line_content(ris_lines_with_numbers, line_num)

      %{
        type: :parse_error,
        line_number: line_num,
        message: msg,
        line_content: line_content
      }
    end)
  end

  defp find_line_content(ris_lines_with_numbers, line_num) do
    case Enum.find(ris_lines_with_numbers, fn {_, num} -> num == line_num end) do
      {content, _} -> content
      nil -> ""
    end
  end

  defp build_and_validate_reference(parsed_results, first_line_num, raw, ris_lines_with_numbers) do
    paper_attrs = build_paper_attributes(parsed_results, first_line_num)

    case validate_reference(paper_attrs) do
      :ok ->
        {:ok, {paper_attrs, raw}}

      {:error, reason} ->
        error = create_validation_error(reason, first_line_num, ris_lines_with_numbers)
        {:error, {error, raw}}
    end
  end

  defp build_paper_attributes(parsed_results, first_line_num) do
    parsed_results
    |> collect_successful_fields()
    |> Map.put(:line_number, first_line_num)
  end

  defp collect_successful_fields(parsed_results) do
    parsed_results
    |> Enum.filter(fn
      {{:ok, _}, _} -> true
      _ -> false
    end)
    |> Enum.reduce(%{}, fn {{:ok, {field, value}}, _}, acc ->
      Map.put(acc, field, value)
    end)
  end

  defp create_validation_error(reason, line_number, ris_lines_with_numbers) do
    # Find the TY line (usually the first line of the reference)
    {first_line_content, _} =
      case ris_lines_with_numbers do
        [first | _] -> first
        [] -> {"", 0}
      end

    %{
      type: :validation_error,
      # Line where reference starts
      line_number: line_number,
      message: reason,
      line_content: first_line_content
    }
  end

  defp validate_reference(attrs) do
    type_of_reference = Map.get(attrs, :type)
    validate_type_of_reference(type_of_reference)
  end

  defp validate_type_of_reference(type) when type in @supported_reference_types do
    :ok
  end

  defp validate_type_of_reference(nil) do
    {:error, dgettext("eyra-paper", "ris.error.missing_type_field")}
  end

  defp validate_type_of_reference(_type) do
    supported_types = Enum.join(@supported_reference_types, ", ")

    {:error,
     dgettext("eyra-paper", "ris.error.unsupported_type", supported_types: supported_types)}
  end

  defp parse_ris_line(line) do
    case Regex.run(~r/^([A-Z0-9]{2,3})\s*-\s*(.*)$/, line) do
      [_, tag, value] ->
        case Map.get(@field_mapping, tag) do
          # Skip unsupported tags instead of treating as error
          nil -> {:skip, tag}
          field -> {:ok, {field, String.trim(value)}}
        end

      _ ->
        {:error, dgettext("eyra-paper", "ris.error.invalid_line_format")}
    end
  end
end
