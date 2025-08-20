defmodule Systems.Zircon.Screening.PaperSetViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  @page_size 10
  alias Frameworks.Pixel

  def view_model(paper_set, assigns) do
    query = Map.get(assigns, :query, nil)
    page_index = Map.get(assigns, :page_index, 0)
    papers = filter_papers(paper_set.papers, query)
    paper_count = papers |> Enum.count()
    page_count = if paper_count == 0, do: 0, else: Float.ceil(paper_count / @page_size) |> round()
    # Handle negative page_index by treating it as 0
    safe_page_index = if page_index < 0, do: 0, else: page_index
    page = papers |> Enum.slice(safe_page_index * @page_size, @page_size)

    search_bar =
      LiveNest.Element.prepare_live_component(:search_bar, Pixel.SearchBar,
        id: "search_bar",
        query_string: "",
        placeholder: dgettext("eyra-zircon", "paper_set.search.placeholder"),
        debounce: "200"
      )

    %{
      page_index: page_index,
      page_count: page_count,
      page: page,
      search_bar: search_bar,
      show_action_bar?: paper_count > @page_size
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
