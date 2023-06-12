defmodule Port.Layouts.Workspace.MenuBuilder do
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
      :settings,
      :profile,
      :signin,
      :signout
    ],
    mobile_navbar: [:menu]
  ]

  use CoreWeb.Menu.Builder, home: :eyra

  @impl true
  def can_access?(_user, _id), do: true
end
