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
  def include_map(user),
    do: %{
      console: Authorization.can_access?(user, Link.Console.Page),
      funding: Authorization.can_access?(user, Budget.FundingPage),
      recruitment: is_researcher?(user),
      pools: has_pools?(user)
    }

  defp is_researcher?(user), do: Map.get(user, :researcher, false)
  defp has_pools?(user), do: not Enum.empty?(Pool.Public.list_owned(user))
end
