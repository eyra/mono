defmodule Next.Layouts.Workspace.MenuBuilder do
  import Core.FeatureFlags

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
      :desktop,
      :projects,
      :admin,
      :onyx,
      :support,
      :todo
    ],
    mobile_navbar: []
  ]

  @secondary [
    default: [
      :helpdesk,
      :profile,
      :signin
    ],
    mobile_navbar: [:menu]
  ]

  use CoreWeb.Menu.Builder, home: :next

  @impl true
  def include_map(user),
    do: %{
      desktop: Systems.Admin.Public.admin?(user) or user.creator,
      projects: Systems.Admin.Public.admin?(user) or user.creator,
      onyx: Systems.Admin.Public.admin?(user) and feature_enabled?(:onyx)
    }
end
