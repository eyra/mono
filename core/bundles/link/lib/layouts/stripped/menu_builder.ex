defmodule Link.Layouts.Stripped.MenuBuilder do
  @behaviour CoreWeb.Menu.Builder

  import CoreWeb.Menu.Helpers

  @impl true
  def build_menu(:desktop_navbar, socket, _user_state, active_item, page_id) do
    %{
      home: live_item(socket, :link, active_item),
      right: build_menu_second_part(socket, page_id)
    }
  end

  @impl true
  def build_menu(:mobile_navbar, socket, _user_state, active_item, page_id) do
    %{
      home: live_item(socket, :link, active_item),
      right: build_menu_second_part(socket, page_id)
    }
  end

  defp build_menu_second_part(socket, page_id, icon_only? \\ true) do
    [
      language_switch_item(socket, page_id, icon_only?)
    ]
  end

end
