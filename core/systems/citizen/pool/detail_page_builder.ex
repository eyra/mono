defmodule Systems.Citizen.Pool.DetailPageBuilder do
  import CoreWeb.Gettext

  alias Systems.{
    Citizen,
    Pool,
    Campaign
  }

  def view_model(pool, assigns) do
    %{
      title: Pool.Model.title(pool),
      tabs: create_tabs(assigns, pool)
    }
  end

  defp create_tabs(
         %{initial_tab: initial_tab},
         %{participants: participants} = pool
       ) do
    campaigns = load_campaigns(pool)

    [
      %{
        id: :citizens,
        title: dgettext("link-citizen", "tabbar.item.citizens"),
        live_component: Citizen.Overview,
        props: %{citizens: participants, pool: pool},
        type: :fullpage,
        active: initial_tab === :citizens
      },
      %{
        id: :campaigns,
        title: dgettext("link-citizen", "tabbar.item.campaigns"),
        live_component: Pool.CampaignsView,
        props: %{campaigns: campaigns},
        type: :fullpage,
        active: initial_tab === :campaigns
      }
    ]
  end

  defp load_campaigns(pool) do
    preload = Campaign.Model.preload_graph(:down)

    Campaign.Public.list_submitted(pool, preload: preload)
    |> Enum.map(&Campaign.Model.flatten(&1))
    |> Enum.map(&Pool.Builders.CampaignItem.view_model(&1))
  end
end
