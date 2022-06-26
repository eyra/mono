defmodule CoreWeb.UI.Navigation.TabletMenu do
  @moduledoc """
    Vertical stacked menu used on the side
  """
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Navigation.Menu

  prop(items, :any, required: true)
  prop(path_provider, :any, required: true)

  def render(assigns) do
    ~F"""
    <div class="fixed z-1 hidden md:block lg:hidden w-tablet-menu-width h-full pt-10 pb-10 h-full">
      <Menu items={@items} path_provider={@path_provider} size={:narrow} />
    </div>
    """
  end
end
