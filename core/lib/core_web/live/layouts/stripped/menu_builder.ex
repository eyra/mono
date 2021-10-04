defmodule CoreWeb.Layouts.Stripped.MenuBuilder do
  @behaviour CoreWeb.Menu.Builder

  import CoreWeb.Menu.Helpers

  @impl true
  def build_menu(:desktop_navbar = menu_id, socket, _user_state, active_item) do
    %{
      home: live_item(socket, menu_id, :eyra, active_item),
      right: build_menu_second_part(socket, menu_id)
    }
  end

  @impl true
  def build_menu(:mobile_navbar = menu_id, socket, _user_state, active_item) do
    %{
      home: live_item(socket, menu_id, :eyra, active_item),
      right: build_menu_second_part(socket, menu_id)
    }
  end

  defp build_menu_second_part(socket, menu_id, icon_only? \\ true) do
    [
      language_switch_item(socket, menu_id, icon_only?)
    ]
  end
end
