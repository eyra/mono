defmodule CoreWeb.Layouts.Website.MobileMenuBuilder do
  @behaviour CoreWeb.Menu.Builder

  import CoreWeb.Layouts.Website.MenuHelpers

  @impl true
  def build_menu(socket, user_state, active_item, page_id) do
    %{
      top: build_menu_first_part(socket, active_item),
      bottom: build_menu_second_part(socket, user_state, active_item, page_id)
    }
  end
end
