defmodule Systems.Account.UserProfilePageBuilder do
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account

  @tabs [
    Systems.Account.ProfileTab,
    Systems.Account.FeaturesTab
  ]

  def view_model(%Account.User{} = user, %{fabric: fabric} = assigns) do
    %{
      title: dgettext("eyra-account", "profile.title"),
      tabs: build_tabs(user, fabric, assigns),
      user: user,
      active_menu_item: :profile
    }
  end

  def build_tabs(user, fabric, _assigns) do
    visible_tabs(user)
    |> Enum.map(& &1.build(user, fabric))
  end

  def tab_keys(user) do
    visible_tabs(user)
    |> Enum.map(& &1.key())
  end

  defp visible_tabs(user) do
    @tabs
    |> Enum.filter(& &1.visible?(user))
  end
end
