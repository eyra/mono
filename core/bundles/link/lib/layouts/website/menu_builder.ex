defmodule Link.Layouts.Website.MenuBuilder do
  @home_flags [
    desktop_navbar: [:wide],
    mobile_navbar: [:wide]
  ]

  @item_flags [
    desktop_navbar: [default: [:title], language: [:icon]],
    mobile_menu: [:icon, :title, :counter],
    mobile_navbar: [:title]
  ]

  @primary [
    :console,
    :marketplace
  ]

  @secondary [
    desktop_navbar: [:signin, :profile, :language],
    mobile_menu: [:language, :signin, :profile],
    mobile_navbar: [:menu]
  ]

  use CoreWeb.Menu.Builder, home: :link
  alias Core.Authorization

  @impl true
  def include_map(user),
    do: %{
      console: Authorization.can_access?(user, Link.Console.Page)
    }
end
