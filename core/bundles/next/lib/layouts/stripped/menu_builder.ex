defmodule Next.Layouts.Stripped.MenuBuilder do
  @home_flags [
    desktop_navbar: [:wide],
    mobile_navbar: [:wide]
  ]

  @item_flags [
    desktop_navbar: [default: [:title], language: [:icon]],
    mobile_navbar: [default: [:title], language: [:icon]]
  ]

  @primary []
  @secondary [:signin, :profile, :language]

  use CoreWeb.Menu.Builder, home: :next

  @impl true
  def include_map(_user), do: %{}
end
