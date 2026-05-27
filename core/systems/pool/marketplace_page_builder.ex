defmodule Systems.Pool.MarketplacePageBuilder do
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Utility.ViewModelBuilder
  alias Systems.Account
  alias Systems.Advert
  alias Systems.Pool

  def view_model(%Pool.Model{} = pool, %{current_user: %Account.User{} = user} = assigns) do
    items = build_items(pool, user, assigns)

    %{
      pool: pool,
      hero: %{
        type: :landing_page,
        params: %{
          title: dgettext("eyra-pool", "marketplace.title")
        }
      },
      breadcrumbs: [
        %{label: dgettext("eyra-pool", "marketplace.breadcrumb.overview"), path: ~p"/"},
        %{
          label: dgettext("eyra-pool", "marketplace.title"),
          path: ~p"/pool/#{pool.id}/marketplace"
        }
      ],
      active_menu_item: :home,
      items: items,
      years: available_years(items),
      include_right_sidepadding?: false
    }
  end

  defp build_items(%Pool.Model{id: pool_id}, %Account.User{} = user, assigns) do
    Advert.Public.list_by_status(:online, preload: Advert.Model.preload_graph(:down))
    |> Enum.filter(
      &(&1.submission.pool_id == pool_id and Advert.Public.validate_open(&1, user) == :ok)
    )
    |> Enum.map(&to_item(&1, assigns))
  end

  defp to_item(%Advert.Model{} = advert, assigns) do
    %{
      year: published_year(advert),
      card: ViewModelBuilder.view_model(advert, {:marketplace, :card}, assigns)
    }
  end

  defp published_year(%Advert.Model{submission: %{submitted_at: %NaiveDateTime{year: year}}}),
    do: year

  defp published_year(%Advert.Model{inserted_at: %NaiveDateTime{year: year}}), do: year

  defp published_year(_), do: nil

  defp available_years(items) do
    items
    |> Enum.map(& &1.year)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort(:desc)
  end
end
