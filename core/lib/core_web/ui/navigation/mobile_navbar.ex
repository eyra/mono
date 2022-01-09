defmodule CoreWeb.UI.Navigation.MobileNavbar do
  @moduledoc """
    Horizontal menu used on top of the page
  """
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Navigation.Navbar

  prop(items, :any, required: true)
  prop(path_provider, :any, required: true)

  def render(assigns) do
    ~F"""
    <div class="md:hidden bg-grey5" >
      <Navbar items={@items} path_provider={@path_provider}/>
    </div>
    """
  end
end
