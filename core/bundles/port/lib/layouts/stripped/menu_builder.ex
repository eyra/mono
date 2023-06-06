defmodule Port.Layouts.Stripped.MenuBuilder do
  @home_flags [
    desktop_navbar: [:wide],
    mobile_navbar: [:wide]
  ]

  @item_flags [
    desktop_navbar: [:icon],
    mobile_navbar: [:icon]
  ]

  @primary []
  @secondary [:language]

  use CoreWeb.Menu.Builder, home: :eyra

  @impl true
  def can_access?(_user, _id), do: true
end
