defmodule CoreWeb.UI.Navigation.DesktopNavbar do
  @moduledoc """
    Horizontal menu used on top of the page
  """
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Navigation.Navbar

  prop(items, :any, required: true)
  prop(path_provider, :any, required: true)

  def render(assigns) do
    ~F"""
    <div class="hidden md:block pr-4" >
      <Navbar items={@items} path_provider={@path_provider}/>
    </div>
    """
  end
end
