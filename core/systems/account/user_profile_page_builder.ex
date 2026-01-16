defmodule Systems.Account.UserProfilePageBuilder do
  use CoreWeb, :verified_routes
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account
  alias Systems.Content.Adaptable

  @tabs [
    Systems.Account.ProfileTab,
    Systems.Account.FeaturesTab
  ]

  def view_model(%Account.User{} = user, %{fabric: fabric} = assigns) do
    %{
      title: dgettext("eyra-account", "profile.title"),
      items: build_items(user, fabric, assigns),
      user: user,
      active_menu_item: :profile
    }
  end

  def build_items(user, fabric, _assigns) do
    visible_tabs(user)
    |> Enum.map(&tab_to_item(&1.build(user, fabric)))
  end

  defp tab_to_item(%{id: id, title: title} = tab) do
    Adaptable.Item.new(id, :profile, title,
      element: Map.get(tab, :element),
      child: Map.get(tab, :child)
    )
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
