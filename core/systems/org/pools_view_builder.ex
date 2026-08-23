defmodule Systems.Org.PoolsViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Fund
  alias Systems.Pool

  def view_model(node, assigns) do
    locale = Map.get(assigns, :locale, :en)

    pools =
      Pool.Public.list_by_orgs(
        [node],
        currency: Fund.CurrencyModel.preload_graph(:full)
      )

    %{
      pools: Enum.map(pools, &pool_item(&1, locale)),
      pool_count: length(pools)
    }
  end

  defp pool_item(
         %Pool.Model{id: id, name: name, currency: currency, director: director} = pool,
         locale
       ) do
    %{
      item: id,
      title: name,
      description: build_description(pool),
      tags: [director_label(director), Fund.CurrencyModel.title(currency, locale)],
      left_actions: [],
      right_actions: []
    }
  end

  defp director_label(:citizen), do: dgettext("eyra-pool", "director.citizen")
  defp director_label(:student), do: dgettext("eyra-pool", "director.student")

  defp build_description(%Pool.Model{} = pool) do
    participant_count = length(Pool.Public.list_participants(pool))
    "#{dgettext("eyra-org", "pools.participants.label")}: #{participant_count}"
  end
end
