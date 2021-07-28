defmodule CoreWeb.Layouts.Workspace.MobileMenuBuilder do
  @behaviour CoreWeb.Menu.Builder

  import CoreWeb.Layouts.Workspace.MenuHelpers

  @impl true
  def build_menu(socket, _user, active_item, page_id) do
    %{
      top: build_menu_first_part(socket, active_item),
      bottom: build_menu_second_part(socket, active_item, page_id)
    }
  end
end
