defmodule Systems.Zircon.Screening.ImportSessionPapersViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Paper.RISEntry
  alias Frameworks.Utility.PaginationHelper

  def view_model(%{entries: entries, reference_file: %{file: %{name: filename}}}, assigns) do
    filter = Map.get(assigns, :filter, "new")

    # Filter entries first (lightweight operation on maps)
    filtered_entries = filter_entries_by_status(entries, filter)

    # Action bar visibility based on total entries for this filter, not search results
    total_filtered_count = length(filtered_entries)

    description =
      dgettext("eyra-zircon", "import_session.phase.prompting.new_papers", filename: filename)

    show_action_bar? = total_filtered_count > 10

    # Paginate and search on raw entries first
    pagination =
      PaginationHelper.paginate_and_search(filtered_entries, assigns,
        filter_fn: &filter_entries/2,
        search_bar_id: "papers_search_bar",
        search_placeholder: dgettext("eyra-zircon", "import_session.papers.search.placeholder")
      )

    # Only convert the current page entries to RISEntry structs
    page_papers = pagination.page_items |> Enum.map(&RISEntry.from_map/1)

    %{
      filter: filter,
      page_papers: page_papers,
      description: description,
      page_index: pagination.page_index,
      page_count: pagination.page_count,
      paper_count: pagination.item_count,
      query: Map.get(assigns, :query, nil),
      search_bar: pagination.search_bar,
      show_action_bar?: show_action_bar?
    }
  end

  # Filter raw map entries for search
  defp filter_entries(entries, nil), do: entries
  defp filter_entries(entries, []), do: entries

  defp filter_entries(entries, query) when is_list(query) do
    Enum.filter(entries, fn entry ->
      # Work with map keys (either atom or string)
      title = get_field(entry, [:title, "title"])
      authors = get_field(entry, [:authors, "authors"])
      doi = get_field(entry, [:doi, "doi"])

      searchable_text =
        [
          title || "",
          format_authors(authors),
          doi || ""
        ]
        |> Enum.join(" ")
        |> String.downcase()

      # AND logic - all query terms must be present
      Enum.all?(query, fn phrase ->
        phrase |> String.downcase() |> then(&String.contains?(searchable_text, &1))
      end)
    end)
  end

  defp format_authors(authors) when is_list(authors), do: Enum.join(authors, " ")
  defp format_authors(authors) when is_binary(authors), do: authors
  defp format_authors(_), do: ""

  # Filter entries by status without converting to structs
  defp filter_entries_by_status(entries, "new") do
    Enum.filter(entries, fn entry ->
      get_field(entry, [:status, "status"]) == "new"
    end)
  end

  defp filter_entries_by_status(entries, "duplicates") do
    Enum.filter(entries, fn entry ->
      get_field(entry, [:status, "status"]) == "duplicate"
    end)
  end

  defp filter_entries_by_status(entries, _filter) do
    filter_entries_by_status(entries, "new")
  end

  # Helper to get field from map with atom or string keys
  defp get_field(map, keys) when is_list(keys) do
    Enum.find_value(keys, fn key -> Map.get(map, key) end)
  end
end
