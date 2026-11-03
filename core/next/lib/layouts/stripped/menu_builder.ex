defmodule NextWeb.Layouts.Stripped.MenuBuilder do
  @home_flags [
    desktop_navbar: [:wide],
    mobile_navbar: [:wide]
  ]

  @item_flags [
    desktop_navbar: [default: [:title]],
    mobile_navbar: [default: [:title]]
  ]

  @primary []
  @secondary [:profile]

  use MicaWeb.Menu.Builder, home: :next

  @impl true
  def include_map(_user), do: %{}
end
