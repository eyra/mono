defmodule Systems.Zircon.Screening.PaperSetViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  @page_size 10
  alias Frameworks.Pixel

  def view_model(paper_set, assigns) do
    query = Map.get(assigns, :query, nil)
    page_index = Map.get(assigns, :page_index, 0)

    # Keep track of total papers before filtering for action bar visibility
    total_paper_count = Enum.count(paper_set.papers)

    papers = filter_papers(paper_set.papers, query)
    paper_count = papers |> Enum.count()
    page_count = if paper_count == 0, do: 0, else: Float.ceil(paper_count / @page_size) |> round()

    # Adjust page_index if it's out of bounds after deletion
    adjusted_page_index =
      cond do
        page_index < 0 -> 0
        page_index >= page_count and page_count > 0 -> page_count - 1
        true -> page_index
      end

    page = papers |> Enum.slice(adjusted_page_index * @page_size, @page_size)

    search_bar =
      LiveNest.Element.prepare_live_component(:search_bar, Pixel.SearchBar,
        id: "search_bar",
        query_string: "",
        placeholder: dgettext("eyra-zircon", "paper_set.search.placeholder"),
        debounce: "200"
      )

    %{
      page_index: adjusted_page_index,
      page_count: page_count,
      page: page,
      search_bar: search_bar,
      show_action_bar?: total_paper_count > @page_size
    }
  end

  def filter_papers(papers, nil) do
    papers
  end

  def filter_papers(papers, []) do
    papers
  end

  def filter_papers(papers, query) do
    Enum.filter(papers, &filter_paper(&1, query))
  end

  defp filter_paper(paper, query) when is_list(query) do
    # AND logic - all query terms must match
    Enum.all?(query, fn phrase -> match_paper?(paper, phrase) end)
  end

  defp match_paper?(%{title: title, authors: authors, doi: doi}, phrase)
       when is_binary(phrase) do
    # Only search in visible fields: title, authors, DOI
    # Handle nil authors by converting to empty list
    authors_list = authors || []

    ([title, doi] ++ authors_list)
    |> Enum.filter(&is_binary/1)
    |> Enum.map(&String.downcase/1)
    |> Enum.any?(fn field ->
      field |> String.contains?(String.downcase(phrase))
    end)
  end
end
