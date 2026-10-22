defmodule Systems.Pool.MarketplaceViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  def view_model(_items, years) do
    %{
      search_placeholder: dgettext("eyra-pool", "marketplace.search.placeholder"),
      year_items: year_items(years)
    }
  end

  @doc """
  Returns `{:ok, path}` for the card with the given id, or `:stale` if the
  card no longer appears in `items` (e.g. it was filtered out between
  render and click).
  """
  def card_path(items, card_id) do
    case Enum.find(items, &(&1.card.id == card_id)) do
      %{card: %{path: path}} -> {:ok, path}
      nil -> :stale
    end
  end

  @doc """
  Filters the marketplace items by year and free-text query, returning the
  underlying cards in the original order.
  """
  def filtered_cards(items, active_year, query) do
    items
    |> filter_by_year(active_year)
    |> filter_by_query(query)
    |> Enum.map(& &1.card)
  end

  defp year_items(years) do
    all = %{
      id: :all,
      value: dgettext("eyra-pool", "marketplace.filter.all"),
      active: true
    }

    year_items =
      years
      |> Enum.map(&%{id: &1, value: Integer.to_string(&1), active: false})

    [all | year_items]
  end

  defp filter_by_year(items, nil), do: items
  defp filter_by_year(items, year), do: Enum.filter(items, &(&1.year == year))

  defp filter_by_query(items, nil), do: items
  defp filter_by_query(items, []), do: items

  defp filter_by_query(items, query) when is_list(query) do
    Enum.filter(items, &matches_query?(&1, query))
  end

  defp matches_query?(item, query) do
    Enum.all?(query, &matches_word?(item, &1))
  end

  defp matches_word?(%{card: %{title: title}}, word) when is_binary(title) and is_binary(word) do
    String.contains?(String.downcase(title), String.downcase(word))
  end

  defp matches_word?(_item, _word), do: false
end
