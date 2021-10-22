defmodule CoreWeb.Menu.Builder do
  @type type :: atom()
  @type socket :: map()
  @type user :: map()
  @type active_item :: atom()
  @type page_id :: binary()
  @type menu :: map()

  @callback build_menu(type, socket, user, active_item) :: menu
end
