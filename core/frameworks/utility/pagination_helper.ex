defmodule Frameworks.Utility.PaginationHelper do
  @moduledoc """
  Helper module for pagination and search functionality in view builders.
  Reduces code duplication across view builders that need pagination.
  """

  @page_size 10

  @doc """
  Handles pagination and search for a collection of items.

  ## Options

  * `:filter_fn` - Function to filter items based on query (required)
  * `:search_bar_id` - ID for the search bar component (required)
  * `:search_placeholder` - Placeholder text for search bar (required)

  ## Example

      pagination = PaginationHelper.paginate_and_search(papers, assigns,
        filter_fn: &filter_papers/2,
        search_bar_id: "papers_search_bar",
        search_placeholder: "Search papers..."
      )
  """
  def paginate_and_search(items, assigns, opts) do
    page_index = Map.get(assigns, :page_index, 0)
    query = Map.get(assigns, :query, nil)

    filter_fn = Keyword.fetch!(opts, :filter_fn)
    search_bar_id = Keyword.fetch!(opts, :search_bar_id)
    search_placeholder = Keyword.fetch!(opts, :search_placeholder)

    filtered_items = filter_fn.(items, query)
    item_count = length(filtered_items)
    page_count = max(1, ceil(item_count / @page_size))
    page_items = filtered_items |> Enum.slice(page_index * @page_size, @page_size)

    search_bar =
      LiveNest.Element.prepare_live_component(:search_bar, Frameworks.Pixel.SearchBar,
        id: search_bar_id,
        query_string: "",
        placeholder: search_placeholder,
        debounce: "200"
      )

    %{
      filtered_items: filtered_items,
      item_count: item_count,
      page_count: page_count,
      page_items: page_items,
      page_index: page_index,
      search_bar: search_bar
    }
  end
end
