defmodule Systems.Account.UserProfilePageBuilder do
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account

  def view_model(%Account.User{} = user, %{fabric: fabric} = assigns) do
    %{
      title: dgettext("eyra-account", "profile.title"),
      tabs: build_tabs(user, fabric, assigns),
      user: user,
      active_menu_item: :profile
    }
  end

  defp build_tabs(user, fabric, assigns) do
    [
      create_profile_tab(user, fabric, assigns),
      create_features_tab(user, fabric, assigns)
    ]
  end

  defp create_profile_tab(user, fabric, _assigns) do
    child =
      Fabric.prepare_child(
        fabric,
        :profile,
        Systems.Account.UserProfileForm,
        %{
          id: :profile_form,
          user: user
        }
      )

    %{
      id: :profile,
      title: dgettext("eyra-account", "profile.tab.profile.title"),
      type: :fullpage,
      child: child,
      ready?: true
    }
  end

  defp create_features_tab(user, fabric, _assigns) do
    child =
      Fabric.prepare_child(
        fabric,
        :features,
        Systems.Account.FeaturesForm,
        %{
          user: user
        }
      )

    %{
      id: :features,
      title: dgettext("eyra-account", "profile.tab.features.title"),
      type: :fullpage,
      child: child,
      ready?: true
    }
  end
end
