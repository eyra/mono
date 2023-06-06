defmodule Next.Layouts.Website.MenuBuilder do
  @home_flags [
    desktop_navbar: [:wide],
    mobile_menu: [:wide]
  ]

  @item_flags [
    desktop_navbar: [default: [:title], language: [:icon]],
    mobile_menu: [:icon, :title, :counter],
    mobile_navbar: [:title]
  ]

  @primary [:console]

  @secondary [
    desktop_navbar: [:signin, :profile, :language],
    mobile_menu: [:language, :profile, :signin],
    mobile_navbar: [:menu]
  ]

  use CoreWeb.Menu.Builder, home: :eyra
  alias Core.Authorization

  @impl true
  def can_access?(user, :console), do: Authorization.can_access?(user, Link.Console.Page)

  @impl true
  def can_access?(_user, _id), do: true
end
