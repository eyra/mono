defmodule Link.Layouts.Workspace.MenuBuilder do
  @behaviour CoreWeb.Menu.Builder
  use Core.FeatureFlags

  import Core.Authorization, only: [can_access?: 2]
  import CoreWeb.Menu.Helpers

  alias Core.NextActions

  @impl true
  def build_menu(:desktop_menu, socket, user_state, active_item, page_id) do
    %{
      home: live_item(socket, :eyra, active_item),
      top: build_menu_first_part(socket, user_state, active_item),
      bottom: build_menu_second_part(socket, active_item, page_id)
    }
  end

  @impl true
  def build_menu(:mobile_navbar, socket, _user, active_item, _page_id) do
    %{
      home: live_item(socket, :eyra, active_item),
      right: [
        alpine_item(:menu, active_item, false, true)
      ]
    }
  end

  @impl true
  def build_menu(:mobile_menu, socket, user_state, active_item, page_id) do
    %{
      top: build_menu_first_part(socket, user_state, active_item),
      bottom: build_menu_second_part(socket, active_item, page_id)
    }
  end

  defp build_menu_first_part(socket, user_state, active_item) do
    next_action_count = NextActions.count_next_actions(user_state)

    []
    |> append(live_item(socket, :dashboard, active_item), can_access?(user_state, Link.Dashboard))
    |> append(live_item(socket, :marketplace, active_item))
    |> append(live_item(socket, :studentpool, active_item), user_state.coordinator)
    |> append(live_item(socket, :surveys, active_item), can_access?(user_state, CoreWeb.Study.New))
    |> append(live_item(socket, :labstudies, active_item), can_access?(user_state, CoreWeb.Study.New))
    |> append(live_item(socket, :todo, active_item, true, next_action_count))
  end

  defp build_menu_second_part(socket, active_item, page_id) do
    [
      language_switch_item(socket, page_id),
      live_item(socket, :settings, active_item),
      live_item(socket, :profile, active_item),
      user_session_item(socket, :signout, active_item),
    ]
    |> append(live_item(socket, :debug, active_item), feature_enabled?(:debug))
  end

  defp append(list, extra, cond \\ true) do
    if cond, do: list ++ [extra], else: list
  end
end
