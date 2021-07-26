defmodule CoreWeb.Menu.Website.MobileMenuBuilder do
  @behaviour CoreWeb.Menu.Builder

  import CoreWeb.Menu.Website.Helpers

  @impl true
  def build_menu(socket, user_state, active_item, page_id) do
    %{
      first: build_menu_first_part(socket, active_item),
      second: build_menu_second_part(socket, user_state, active_item, page_id)
    }
  end
end
