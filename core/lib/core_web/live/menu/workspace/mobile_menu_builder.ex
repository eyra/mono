defmodule CoreWeb.Menu.Workspace.MobileMenuBuilder do
  @behaviour CoreWeb.Menu.Builder

  import CoreWeb.Menu.Workspace.Helpers

  @impl true
  def build_menu(socket, _user, active_item, page_id) do
    %{
      first: build_menu_first_part(socket, active_item),
      second: build_menu_second_part(socket, active_item, page_id)
    }
  end
end
