defmodule Next.Layouts.Website.MenuBuilder do
  @home_flags [
    desktop_navbar: [:wide],
    mobile_navbar: [:narrow],
    mobile_menu: [:narrow]
  ]

  @item_flags [
    desktop_navbar: [default: [:title]],
    mobile_menu: [:icon, :title, :counter],
    mobile_navbar: [:title]
  ]

  @primary [:workspace]

  @secondary [
    desktop_navbar: [:signin, :profile],
    mobile_menu: [:profile, :signin],
    mobile_navbar: [:menu]
  ]

  use CoreWeb.Menu.Builder, home: :next

  @impl true

  def include_map(nil),
    do: %{
      workspace: false
    }

  def include_map(user),
    do: %{
      workspace: Systems.Admin.Public.admin?(user) or user.creator
    }
end
