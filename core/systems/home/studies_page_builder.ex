defmodule Systems.Home.StudiesPageBuilder do
  use CoreWeb, :verified_routes

  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Utility.ViewModelBuilder
  alias Systems.Account
  alias Systems.Advert
  alias Systems.Pool

  # For guest users (access is blocked in the page mount, but guard here too)
  def view_model(_, %{current_user: nil}) do
    base_vm([], [])
  end

  # For logged in users
  def view_model(_, %{current_user: user} = assigns) do
    panl? = Pool.Public.participant?(:panl, user)
    put_locale(user, panl?)

    items = build_items(user, assigns)
    base_vm(items, available_years(items))
  end

  defp base_vm(items, years) do
    %{
      hero: %{
        type: :landing_page,
        params: %{
          title: dgettext("eyra-home", "studies.title")
        }
      },
      breadcrumbs: [
        %{label: dgettext("eyra-home", "overview.breadcrumb"), path: ~p"/"},
        %{label: dgettext("eyra-home", "studies.title"), path: ~p"/studies"}
      ],
      active_menu_item: :home,
      items: items,
      years: years,
      include_right_sidepadding?: false
    }
  end

  defp build_items(%Account.User{} = user, assigns) do
    Advert.Public.list_by_status(:online, preload: Advert.Model.preload_graph(:down))
    |> Enum.filter(&(Advert.Public.validate_open(&1, user) == :ok))
    |> Enum.map(&to_item(&1, assigns))
  end

  defp to_item(%Advert.Model{} = advert, assigns) do
    %{
      year: published_year(advert),
      card: ViewModelBuilder.view_model(advert, {:marketplace, :card}, assigns)
    }
  end

  defp published_year(%Advert.Model{submission: %{submitted_at: %NaiveDateTime{} = submitted_at}}) do
    submitted_at.year
  end

  defp published_year(%Advert.Model{inserted_at: %NaiveDateTime{} = inserted_at}) do
    inserted_at.year
  end

  defp published_year(_), do: nil

  defp available_years(items) do
    items
    |> Enum.map(& &1.year)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort(:desc)
  end

  defp put_locale(%Account.User{creator: false}, true) do
    CoreWeb.Live.Hook.Locale.put_locale("nl")
  end

  defp put_locale(_, _) do
    CoreWeb.Live.Hook.Locale.put_locale("en")
  end
end
