defmodule CoreWeb.Menu.Website.MobileNavbarBuilder do
  @behaviour CoreWeb.Menu.Builder

  import CoreWeb.Menu.Helpers

  @impl true
  def build_menu(socket, _user, active_item, _page_id) do
    %{
      home: live_item(socket, :eyra, active_item),
      second: [
        alpine_item(:menu, active_item, false, true)
      ]
    }
  end
end
