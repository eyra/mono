defmodule CoreWeb.Menu.Website.DesktopNavbarBuilder do
  @behaviour CoreWeb.Menu.Builder

  import CoreWeb.Menu.Helpers
  import CoreWeb.Menu.Website.Helpers

  @impl true
  def build_menu(socket, user_state, active_item, page_id) do
    %{
      home: live_item(socket, :eyra, active_item),
      first: build_menu_first_part(socket, active_item, false),
      second: build_menu_second_part(socket, user_state, active_item, page_id, false)
    }
  end
end
