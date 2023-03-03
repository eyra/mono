defmodule Systems.Citizen.Pool.DetailPageBuilder do
  import CoreWeb.Gettext

  alias Systems.{
    Citizen,
    Pool,
    Campaign
  }

  def view_model(pool, assigns, url_resolver) do
    %{
      title: Pool.Model.title(pool),
      tabs: create_tabs(assigns, url_resolver, pool)
    }
  end

  defp create_tabs(
         %{initial_tab: initial_tab},
         url_resolver,
         %{participants: participants} = pool
       ) do
    campaigns = load_campaigns(url_resolver, pool)

    [
      %{
        id: :citizens,
        title: dgettext("link-citizen", "tabbar.item.citizens"),
        component: Citizen.Overview,
        props: %{citizens: participants, pool: pool},
        type: :fullpage,
        active: initial_tab === :citizens
      },
      %{
        id: :campaigns,
        title: dgettext("link-citizen", "tabbar.item.campaigns"),
        component: Pool.CampaignsView,
        props: %{campaigns: campaigns},
        type: :fullpage,
        active: initial_tab === :campaigns
      }
    ]
  end

  defp load_campaigns(url_resolver, pool) do
    preload = Campaign.Model.preload_graph(:full)

    Campaign.Public.list_submitted(pool, preload: preload)
    |> Enum.map(&Campaign.Model.flatten(&1))
    |> Enum.map(&Pool.Builders.CampaignItem.view_model(url_resolver, &1))
  end
end
