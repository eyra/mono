# `Frameworks.Utility.PaginationHelper`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/utility/pagination_helper.ex#L1)

Helper module for pagination and search functionality in view builders.
Reduces code duplication across view builders that need pagination.

# `paginate_and_search`

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

---

*Consult [api-reference.md](api-reference.md) for complete listing*
