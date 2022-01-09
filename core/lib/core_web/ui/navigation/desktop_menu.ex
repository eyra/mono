defmodule CoreWeb.UI.Navigation.DesktopMenu do
  @moduledoc """
    Vertical stacked menu used on the side
  """
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Navigation.Menu

  prop(items, :any, required: true)
  prop(path_provider, :any, required: true)

  def render(assigns) do
    ~F"""
    <div class="fixed z-1 hidden lg:block w-desktop-menu-width h-full pl-10 pr-8 pt-10 pb-10 h-full">
      <Menu items={@items} path_provider={@path_provider} size={:wide}/>
    </div>
    """
  end
end
