defmodule Systems.Paper.RISProcessor do
  @moduledoc """
  Business logic for processing parsed RIS references.

  Handles:
  - Checking if papers already exist in the database
  - Building changesets for new papers
  - Categorizing references as new/existing/error
  """

  require Logger
  use Gettext, backend: CoreWeb.Gettext
  alias Systems.Paper

  @doc """
  Process parsed RIS references and categorize them.

  Takes parsed reference data from RISParser and:
  1. Validates the reference data
  2. Detects intrinsic duplicates within the file
  3. Checks if papers already exist in the database
  4. Builds changesets for new papers

  Returns categorized references ready for import.
  """
  def process_references(parsed_references, paper_set) do
    # Build a map to track which references are intrinsic duplicates
    intrinsic_duplicate_indices = find_intrinsic_duplicate_indices(parsed_references)

    # Process each reference with its index
    parsed_references
    |> Enum.with_index()
    |> Enum.map(fn
      {{:ok, {attrs, raw}}, index} ->
        if Map.has_key?(intrinsic_duplicate_indices, index) do
          # This is a duplicate of an earlier entry in the file
          {{:error, format_intrinsic_duplicate_error({attrs, raw}, index)}, raw}
        else
          process_single_reference({attrs, raw}, paper_set)
        end

      {{:error, {reason, raw}}, _index} ->
        {{:error, reason}, raw}
    end)
  end

  # Find indices of references that are duplicates of earlier entries
  defp find_intrinsic_duplicate_indices(parsed_references) do
    parsed_references
    |> Enum.with_index()
    |> Enum.reduce({[], %{}}, fn
      {{:ok, {attrs, _raw}}, current_index}, {seen_refs, duplicate_map} ->
        # Check if this reference matches any previously seen reference
        case find_matching_reference(attrs, seen_refs) do
          nil ->
            # Not a duplicate, add to seen references
            {[{attrs, current_index} | seen_refs], duplicate_map}

          _original_index ->
            # This is a duplicate, mark it
            {seen_refs, Map.put(duplicate_map, current_index, true)}
        end

      {{:error, _}, _index}, acc ->
        # Skip error entries
        acc
    end)
    # Return just the duplicate map
    |> elem(1)
  end

  # Find if a reference matches any in the seen list
  defp find_matching_reference(attrs, seen_refs) do
    Enum.find(seen_refs, fn {seen_attrs, _index} ->
      Paper.Private.papers_match?(attrs, seen_attrs)
    end)
  end

  defp format_intrinsic_duplicate_error({attrs, _raw}, _index) do
    doi = Map.get(attrs, :doi)
    title = Map.get(attrs, :title)
    # Get the actual line number from attrs
    line_number = Map.get(attrs, :line_number, 0)

    # The content should be the DOI or title that caused the duplicate
    content =
      cond do
        doi && doi != "" ->
          doi

        title && title != "" ->
          title

        true ->
          ""
      end

    # Return a structured error map like parsing errors
    %{
      # Use the actual line number from the RIS file
      "line" => line_number,
      "message" => dgettext("eyra-paper", "ris.error.duplicate_paper_in_file"),
      "content" => content
    }
  end

  @doc """
  Build summary statistics from processed references.
  """
  def build_summary(processed_references) do
    Enum.reduce(processed_references, %{total: 0, new: 0, existing: 0, errors: 0}, fn
      {{:ok, :new, _}, _}, acc ->
        %{acc | total: acc.total + 1, new: acc.new + 1}

      {{:ok, :existing, _, _}, _}, acc ->
        %{acc | total: acc.total + 1, existing: acc.existing + 1}

      {{:error, _}, _}, acc ->
        %{acc | total: acc.total + 1, errors: acc.errors + 1}
    end)
  end

  @doc """
  Format processed references for API response.
  """
  def format_references(processed_references) do
    Enum.map(processed_references, fn
      {{:ok, :new, attrs}, raw} ->
        %{
          status: :new,
          title: attrs.title,
          doi: attrs.doi,
          raw: raw
        }

      {{:ok, :existing, attrs, paper_id}, raw} ->
        %{
          status: :existing,
          title: attrs.title,
          doi: attrs.doi,
          paper_id: paper_id,
          raw: raw
        }

      {{:error, reason}, raw} ->
        %{
          status: :error,
          error: reason,
          raw: raw
        }
    end)
  end

  # Private functions

  defp process_single_reference({attrs, raw}, paper_set) do
    case Paper.Private.check_paper_exists(attrs, paper_set) do
      {:existing, paper} ->
        processed_attrs = process_paper_attributes(attrs)
        {{:ok, :existing, processed_attrs, paper.id}, raw}

      :new ->
        processed_attrs = process_paper_attributes(attrs)
        {{:ok, :new, processed_attrs}, raw}
    end
  end

  defp process_paper_attributes(attrs) do
    %{
      doi: Map.get(attrs, :doi),
      title: Map.get(attrs, :title),
      subtitle: Map.get(attrs, :subtitle),
      year: Map.get(attrs, :year),
      date: Map.get(attrs, :date),
      abbreviated_journal: Map.get(attrs, :abbreviated_journal),
      authors: process_authors_field(Map.get(attrs, :authors)),
      abstract: Map.get(attrs, :abstract),
      keywords: process_keywords_field(Map.get(attrs, :keywords))
    }
  end

  defp process_authors_field(authors) do
    case authors do
      nil ->
        []

      "" ->
        []

      author_string when is_binary(author_string) ->
        parse_author_string(author_string)

      authors_list when is_list(authors_list) ->
        authors_list

      _ ->
        []
    end
  end

  defp parse_author_string(author_string) do
    author_string
    |> String.split(~r/;\s*|\s+and\s+/, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp process_keywords_field(keywords) do
    case keywords do
      nil ->
        []

      "" ->
        []

      keyword_string when is_binary(keyword_string) ->
        parse_keyword_string(keyword_string)

      keywords_list when is_list(keywords_list) ->
        keywords_list

      _ ->
        []
    end
  end

  defp parse_keyword_string(keyword_string) do
    keyword_string
    |> String.split(~r/;\s*|,\s*/, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  @doc """
  Create a changeset for a new paper (only call during actual import).
  Accepts either a map with atom keys or a RISEntry struct.
  """
  def build_paper_changeset(ref, paper_set) do
    # Create a new version for the paper
    version = Systems.Version.Public.prepare_first()

    Paper.Public.prepare_paper(
      Map.get(ref, :doi),
      Map.get(ref, :title),
      Map.get(ref, :subtitle),
      Map.get(ref, :year),
      Map.get(ref, :date),
      Map.get(ref, :abbreviated_journal),
      Map.get(ref, :authors, []),
      Map.get(ref, :abstract),
      Map.get(ref, :keywords, [])
    )
    |> Ecto.Changeset.put_assoc(:version, version)
    |> Ecto.Changeset.put_assoc(:sets, [paper_set])
  end
end
