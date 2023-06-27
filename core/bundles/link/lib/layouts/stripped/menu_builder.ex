defmodule Link.Layouts.Stripped.MenuBuilder do
  @home_flags [
    desktop_navbar: [:wide],
    mobile_menu: [:narrow]
  ]

  @item_flags [
    desktop_navbar: [:icon],
    mobile_navbar: [:icon]
  ]

  @primary []
  @secondary [:language]

  use CoreWeb.Menu.Builder, home: :link

  @impl true
  def include_map(_user), do: %{}
end
