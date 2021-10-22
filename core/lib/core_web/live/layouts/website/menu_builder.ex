defmodule CoreWeb.Layouts.Website.MenuBuilder do
  @behaviour CoreWeb.Menu.Builder

  import CoreWeb.Menu.Helpers

  @impl true
  def build_menu(:desktop_navbar = menu_id, socket, user_state, active_item) do
    %{
      home: live_item(socket, menu_id, :eyra, active_item),
      left: build_menu_first_part(socket, menu_id, active_item, false),
      right: build_menu_second_part(socket, menu_id, user_state, active_item, true)
    }
  end

  @impl true
  def build_menu(:mobile_menu = menu_id, socket, user_state, active_item) do
    %{
      top: build_menu_first_part(socket, menu_id, active_item),
      bottom: build_menu_second_part(socket, menu_id, user_state, active_item, false)
    }
  end

  @impl true
  def build_menu(:mobile_navbar = menu_id, socket, _user, active_item) do
    %{
      home: live_item(socket, menu_id, :eyra, active_item),
      right: [
        alpine_item(menu_id, :menu, active_item, false, true)
      ]
    }
  end

  defp build_menu_first_part(socket, menu_id, active_item, use_icon \\ true) do
    [
      live_item(socket, menu_id, :dashboard, active_item, use_icon),
      live_item(socket, menu_id, :marketplace, active_item, use_icon)
    ]
  end

  defp build_menu_second_part(socket, menu_id, user_state, active_item, navbar?) do
    is_logged_in = user_state != nil

    [
      language_switch_item(socket, menu_id, navbar?),
      account_item(socket, menu_id, is_logged_in, active_item, not navbar?)
    ]
  end
end
