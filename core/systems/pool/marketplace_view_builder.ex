defmodule Systems.Pool.MarketplaceViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  def view_model(_items, years) do
    %{
      search_placeholder: dgettext("eyra-pool", "marketplace.search.placeholder"),
      year_items: year_items(years)
    }
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
end
