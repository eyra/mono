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
    desktop_navbar: [:signin, :signout, :language],
    mobile_menu: [:language, :signin, :signout],
    mobile_navbar: [:menu]
  ]

  use CoreWeb.Menu.Builder, home: :link
  alias Core.Authorization

  @impl true
  def can_access?(user, :console), do: Authorization.can_access?(user, Link.Console.Page)

  @impl true
  def can_access?(_user, _id), do: true
end
