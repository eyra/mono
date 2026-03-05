defmodule Next.Layouts.Stripped.MenuBuilder do
  @moduledoc false
  use CoreWeb.Menu.Builder, home: :next

  @home_flags [
    desktop_navbar: [:wide],
    mobile_navbar: [:wide]
  ]

  @item_flags [
    desktop_navbar: [default: [:title]],
    mobile_navbar: [default: [:title]]
  ]

  @primary []
  @secondary [:signin, :profile]

  @impl true
  def include_map(_user), do: %{}
end
