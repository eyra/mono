defmodule Link.Layouts.Workspace.MenuBuilder do
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
      :admin,
      :recruitment,
      :pools,
      :marketplace,
      :funding,
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
      :signout,
      :debug
    ],
    mobile_navbar: [:menu]
  ]

  use CoreWeb.Menu.Builder, home: :link
  alias Core.Authorization

  alias Systems.{
    Pool,
    Budget
  }

  @impl true
  def can_access?(user, :console), do: Authorization.can_access?(user, Link.Console.Page)

  @impl true
  def can_access?(user, :funding), do: Authorization.can_access?(user, Budget.FundingPage)

  @impl true
  def can_access?(user, :recruitment), do: is_researcher?(user)

  @impl true
  def can_access?(user, :pools), do: has_pools?(user)

  @impl true
  def can_access?(_user, _id), do: true

  defp is_researcher?(user), do: Map.get(user, :researcher, false)
  defp has_pools?(user), do: not Enum.empty?(Pool.Public.list_owned(user))
end
