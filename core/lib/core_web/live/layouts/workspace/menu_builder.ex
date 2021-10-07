defmodule CoreWeb.Layouts.Workspace.MenuBuilder do
  @behaviour CoreWeb.Menu.Builder

  import Core.Admin
  import CoreWeb.Menu.Helpers

  @impl true
  def build_menu(:desktop_menu = menu_id, socket, user, active_item) do
    %{
      home: live_item(socket, menu_id, :eyra, active_item),
      top: build_menu_first_part(socket, menu_id, user, active_item),
      bottom: build_menu_second_part(socket, menu_id, active_item)
    }
  end

  @impl true
  def build_menu(:tablet_menu = menu_id, socket, user, active_item) do
    %{
      home: live_item(socket, menu_id, :eyra, active_item),
      top: build_menu_first_part(socket, menu_id, user, active_item),
      bottom: build_menu_second_part(socket, menu_id, active_item)
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

  @impl true
  def build_menu(:mobile_menu = menu_id, socket, user, active_item) do
    %{
      top: build_menu_first_part(socket, menu_id, user, active_item),
      bottom: build_menu_second_part(socket, menu_id, active_item)
    }
  end

  defp build_menu_first_part(socket, menu_id, %{email: email} = _user, active_item) do
    []
    |> append(live_item(socket, menu_id, :dashboard, active_item))
    |> append(live_item(socket, menu_id, :permissions, active_item), admin?(email))
    |> append(live_item(socket, menu_id, :support, active_item), admin?(email))
    |> append(live_item(socket, menu_id, :marketplace, active_item))
    |> append(live_item(socket, menu_id, :todo, active_item))
    |> append(live_item(socket, menu_id, :payments, active_item))
  end

  defp build_menu_second_part(socket, menu_id, active_item) do
    [
      language_switch_item(socket, menu_id),
      live_item(socket, menu_id, :helpdesk, active_item),
      live_item(socket, menu_id, :settings, active_item),
      live_item(socket, menu_id, :profile, active_item),
      user_session_item(socket, menu_id, :signout, active_item)
    ]
  end

  defp append(list, extra, condition \\ true) do
    if condition, do: list ++ [extra], else: list
  end
end
