defmodule CoreWeb.Layouts.Workspace.DesktopMenuBuilder do
  @behaviour CoreWeb.Menu.Builder

  import CoreWeb.Menu.Helpers
  import CoreWeb.Layouts.Workspace.MenuHelpers

  @impl true
  def build_menu(socket, _user, active_item, page_id) do
    %{
      home: live_item(socket, :eyra, active_item),
      top: build_menu_first_part(socket, active_item),
      bottom: build_menu_second_part(socket, active_item, page_id)
    }
  end
end
