defmodule CoreWeb.Menu.Workspace.Helpers do
  import CoreWeb.Menu.Helpers

  def build_menu_first_part(socket, active_item) do
    [
      live_item(socket, :dashboard, active_item),
      live_item(socket, :marketplace, active_item),
      live_item(socket, :inbox, active_item),
      live_item(socket, :payments, active_item)
    ]
  end

  def build_menu_second_part(socket, active_item, page_id) do
    [
      language_switch_item(socket, page_id),
      live_item(socket, :settings, active_item),
      live_item(socket, :profile, active_item),
      user_session_item(socket, :signout, active_item)
    ]
  end
end
