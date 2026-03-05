defmodule Self.Layouts.Stripped.MenuBuilder do
  @moduledoc false
  use CoreWeb.Menu.Builder, home: :self

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

  @impl true
  def include_map(_user), do: %{}
end
