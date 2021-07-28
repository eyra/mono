defmodule CoreWeb.Layouts.Website.DesktopNavbarBuilder do
  @behaviour CoreWeb.Menu.Builder

  import CoreWeb.Menu.Helpers
  import CoreWeb.Layouts.Website.MenuHelpers

  @impl true
  def build_menu(socket, user_state, active_item, page_id) do
    %{
      home: live_item(socket, :eyra, active_item),
      left: build_menu_first_part(socket, active_item, false),
      right: build_menu_second_part(socket, user_state, active_item, page_id, false)
    }
  end
end
