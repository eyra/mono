defmodule Link.Layouts.Stripped.MenuBuilder do
  @behaviour CoreWeb.Menu.Builder

  import CoreWeb.Menu.Helpers

  @impl true
  def build_menu(:desktop_navbar, socket, _user_state, active_item, _page_id) do
    %{
      home: live_item(socket, :link, active_item)
    }
  end

  @impl true
  def build_menu(:mobile_navbar, socket, _user, active_item, _page_id) do
    %{
      home: live_item(socket, :link, active_item)
    }
  end
end
