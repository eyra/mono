defmodule CoreWeb.Layouts.Website.MenuHelpers do
  import CoreWeb.Menu.Helpers

  alias CoreWeb.User.Service, as: UserService

  def build_menu_first_part(socket, active_item, use_icon \\ true) do
    [
      live_item(socket, :dashboard, active_item, use_icon),
      live_item(socket, :marketplace, active_item, use_icon)
    ]
  end

  def build_menu_second_part(socket, user_state, active_item, page_id, use_icon \\ true) do
    is_logged_in = UserService.is_logged_in?(user_state)

    [
      account_item(socket, is_logged_in, active_item, use_icon),
      language_switch_item(socket, page_id)
    ]
  end
end
