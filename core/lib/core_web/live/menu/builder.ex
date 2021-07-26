defmodule CoreWeb.Menu.Builder do
  @moduledoc """
  Generic behaviour of a Tool
  """
  alias EyraUI.Navigation.MenuItem
  alias Phoenix.Socket

  @type socket :: Socket.t()
  @type active_item :: atom
  @type page_id :: binary
  @type user :: %{}

  @type build_menu_result :: %{
          home: MenuItem.ViewModel.t(),
          first: list(MenuItem.ViewModel.t()),
          second: list(MenuItem.ViewModel.t())
        }

  @callback build_menu(socket, user, active_item, page_id) :: build_menu_result
end
