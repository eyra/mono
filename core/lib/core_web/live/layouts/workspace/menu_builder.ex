defmodule CoreWeb.Layouts.Workspace.MenuBuilder do
  @behaviour CoreWeb.Menu.Builder

  import CoreWeb.Menu.Helpers

  @impl true
  def build_menu(:desktop_menu, socket, _user, active_item, page_id) do
    %{
      home: live_item(socket, :eyra, active_item),
      top: build_menu_first_part(socket, active_item),
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
  def build_menu(:mobile_menu, socket, _user, active_item, page_id) do
    %{
      top: build_menu_first_part(socket, active_item),
      bottom: build_menu_second_part(socket, active_item, page_id)
    }
  end

  defp build_menu_first_part(socket, active_item) do
    [
      live_item(socket, :dashboard, active_item),
      live_item(socket, :marketplace, active_item),
      live_item(socket, :todo, active_item),
      live_item(socket, :payments, active_item)
    ]
  end

  defp build_menu_second_part(socket, active_item, page_id) do
    [
      language_switch_item(socket, page_id),
      live_item(socket, :helpdesk, active_item),
      live_item(socket, :settings, active_item),
      live_item(socket, :profile, active_item),
      user_session_item(socket, :signout, active_item)
    ]
  end
end
