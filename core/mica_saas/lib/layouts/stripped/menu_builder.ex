defmodule MicaSaasWeb.Layouts.Stripped.MenuBuilder do
  @home_flags [
    desktop_navbar: [:wide],
    mobile_navbar: [:wide]
  ]

  @item_flags [
    desktop_navbar: [:icon],
    mobile_navbar: [:icon]
  ]

  @primary []
  @secondary []

  use MicaWeb.Menu.Builder, home: :self

  @impl true
  def include_map(_user), do: %{}
end
