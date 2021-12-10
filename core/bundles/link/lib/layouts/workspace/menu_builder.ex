defmodule Link.Layouts.Workspace.MenuBuilder do
  @behaviour CoreWeb.Menu.Builder
  use Core.FeatureFlags

  import Core.Authorization, only: [can_access?: 2]
  import CoreWeb.Menu.Helpers

  import Systems.Admin.Context

  alias Systems.NextAction
  alias Systems.Support

  @impl true
  def build_menu(:desktop_menu = menu_id, socket, user_state, active_item) do
    %{
      home: live_item(socket, menu_id, :link, active_item),
      top: build_menu_first_part(socket, menu_id, user_state, active_item),
      bottom: build_menu_second_part(socket, menu_id, user_state, active_item)
    }
  end

  @impl true
  def build_menu(:tablet_menu = menu_id, socket, user_state, active_item) do
    %{
      home: live_item(socket, menu_id, :link, active_item),
      top: build_menu_first_part(socket, menu_id, user_state, active_item),
      bottom: build_menu_second_part(socket, menu_id, user_state, active_item)
    }
  end

  @impl true
  def build_menu(:mobile_navbar = menu_id, socket, _user, active_item) do
    %{
      home: live_item(socket, menu_id, :link, active_item),
      right: [
        alpine_item(menu_id, :menu, active_item, false, true)
      ]
    }
  end

  @impl true
  def build_menu(:mobile_menu = menu_id, socket, user_state, active_item) do
    %{
      top: build_menu_first_part(socket, menu_id, user_state, active_item),
      bottom: build_menu_second_part(socket, menu_id, user_state, active_item)
    }
  end

  defp build_menu_first_part(socket, menu_id, %{email: email} = user_state, active_item) do
    next_action_count = NextAction.Context.count_next_actions(user_state)
    support_count = Support.Context.count_open_tickets()

    []
    |> append(
      live_item(socket, menu_id, :dashboard, active_item),
      can_access?(user_state, Link.Dashboard)
    )
    |> append(live_item(socket, menu_id, :permissions, active_item), admin?(email))
    |> append(
      live_item(socket, menu_id, :support, active_item, true, support_count),
      admin?(email)
    )
    |> append(
      live_item(socket, menu_id, :recruitment, active_item),
      user_state.researcher
    )
    |> append(live_item(socket, menu_id, :studentpool, active_item), user_state.coordinator)
    |> append(live_item(socket, menu_id, :marketplace, active_item))
    |> append(live_item(socket, menu_id, :todo, active_item, true, next_action_count))
  end

  defp build_menu_second_part(socket, menu_id, %{email: email} = _user_state, active_item) do
    [
      language_switch_item(socket, menu_id),
      live_item(socket, menu_id, :helpdesk, active_item),
      live_item(socket, menu_id, :settings, active_item),
      live_item(socket, menu_id, :profile, active_item),
      user_session_item(socket, menu_id, :signout, active_item)
    ]
    |> append(live_item(socket, menu_id, :debug, active_item), admin?(email))
  end

  defp append(list, extra, condition \\ true) do
    if condition, do: list ++ [extra], else: list
  end
end
