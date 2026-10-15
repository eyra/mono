defmodule Self.Layouts.Website.MenuBuilder do
  @home_flags [
    desktop_navbar: [:wide],
    mobile_menu: [:narrow]
  ]

  @item_flags [
    desktop_navbar: [default: [:title]],
    mobile_menu: [:icon, :title, :counter],
    mobile_navbar: [:title]
  ]

  @primary [:desktop]

  @secondary [
    desktop_navbar: [:signin, :profile],
    mobile_menu: [:profile, :signin],
    mobile_navbar: [:menu]
  ]

  use CoreWeb.Menu.Builder, home: :self

  @impl true
  def include_map(_user), do: %{}
end
