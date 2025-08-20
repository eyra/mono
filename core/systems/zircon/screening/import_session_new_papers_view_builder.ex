defmodule Systems.Zircon.Screening.ImportSessionNewPapersViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Paper.RISEntry
  alias Frameworks.Utility.PaginationHelper

  def view_model(%{entries: entries, reference_file: %{file: %{name: filename}}}, assigns) do
    new_papers = extract_new_papers(entries)

    description =
      dgettext("eyra-zircon", "import_session.phase.prompting.new_papers", filename: filename)

    show_action_bar? = length(new_papers) > 10

    pagination =
      PaginationHelper.paginate_and_search(new_papers, assigns,
        filter_fn: &filter_papers/2,
        search_bar_id: "papers_search_bar",
        search_placeholder: dgettext("eyra-zircon", "import_session.papers.search.placeholder")
      )

    %{
      new_papers: new_papers,
      filtered_papers: pagination.filtered_items,
      page_papers: pagination.page_items,
      description: description,
      page_index: pagination.page_index,
      page_count: pagination.page_count,
      paper_count: pagination.item_count,
      query: Map.get(assigns, :query, nil),
      search_bar: pagination.search_bar,
      show_action_bar?: show_action_bar?
    }
  end

  defp filter_papers(papers, nil), do: papers
  defp filter_papers(papers, []), do: papers

  defp filter_papers(papers, query) when is_list(query) do
    Enum.filter(papers, fn paper ->
      # Only search in visible fields: title, authors, DOI
      searchable_text =
        [
          Map.get(paper, :title, ""),
          format_authors(Map.get(paper, :authors)),
          Map.get(paper, :doi, "")
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

  defp extract_new_papers(entries) do
    entries
    |> Enum.map(&RISEntry.from_map/1)
    |> Enum.filter(&(&1.status == "new"))
  end
end
