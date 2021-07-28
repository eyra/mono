defmodule CoreWeb.Menu.Builder do
  @moduledoc """
  Generic behaviour of a Tool
  """
  alias Phoenix.Socket

  @type socket :: Socket.t()
  @type active_item :: atom()
  @type page_id :: binary()
  @type user :: map()
  @type menu :: map()

  @callback build_menu(socket, user, active_item, page_id) :: menu
end
