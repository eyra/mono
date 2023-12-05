defmodule Self.Layouts.Workspace.MenuBuilder do
  @home_flags [
    desktop_menu: [:wide],
    tablet_menu: [:narrow],
    mobile_navbar: [:wide]
  ]

  @item_flags [
    desktop_menu: [:icon, :title, :counter],
    tablet_menu: [:icon],
    mobile_navbar: [:title],
    mobile_menu: [:icon, :title, :counter]
  ]

  @primary [
    default: [
      :console,
      :projects,
      :admin,
      :support,
      :todo
    ],
    mobile_navbar: []
  ]

  @secondary [
    default: [
      :language,
      :helpdesk,
      :profile,
      :signin
    ],
    mobile_navbar: [:menu]
  ]

  use CoreWeb.Menu.Builder, home: :self
  alias Core.Authorization

  @impl true
  def include_map(user),
    do: %{
      console: Authorization.can_access?(user, Self.Console.Page),
      projects: Systems.Admin.Public.admin?(user) or user.researcher
    }
end
