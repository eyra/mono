defmodule Systems.Zircon.Screening.ImportSessionErrorsViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Paper.RISEntry
  alias Frameworks.Utility.PaginationHelper

  def view_model(%{entries: entries, reference_file: %{file: %{name: _filename}}}, assigns) do
    errors = extract_errors(entries)
    show_action_bar? = length(errors) > 10

    pagination =
      PaginationHelper.paginate_and_search(errors, assigns,
        filter_fn: &filter_errors/2,
        search_bar_id: "errors_search_bar",
        search_placeholder: dgettext("eyra-zircon", "import_session.errors.search.placeholder")
      )

    %{
      errors: errors,
      filtered_errors: pagination.filtered_items,
      page_errors: pagination.page_items,
      page_index: pagination.page_index,
      page_count: pagination.page_count,
      error_count: pagination.item_count,
      query: Map.get(assigns, :query, nil),
      search_bar: pagination.search_bar,
      show_action_bar?: show_action_bar?
    }
  end

  defp filter_errors(errors, nil), do: errors
  defp filter_errors(errors, []), do: errors

  defp filter_errors(errors, query) when is_list(query) do
    Enum.filter(errors, fn error ->
      # Use Map.get with defaults for clean access
      line = Map.get(error, :line, "")

      searchable_text =
        [
          "Line #{line}",
          Map.get(error, :error, ""),
          Map.get(error, :content, "")
        ]
        |> Enum.join(" ")
        |> String.downcase()

      # AND logic - all query terms must be present
      Enum.all?(query, fn phrase ->
        phrase |> String.downcase() |> then(&String.contains?(searchable_text, &1))
      end)
    end)
  end

  defp extract_errors(entries) do
    RISEntry.process_entry_errors(entries)
  end
end
