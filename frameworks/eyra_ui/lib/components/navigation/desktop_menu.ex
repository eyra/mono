defmodule EyraUI.Navigation.DesktopMenu do
  @moduledoc """
    Vertical stacked menu used on the side
  """
  use Surface.Component

  alias EyraUI.Navigation.Menu

  prop(items, :any, required: true)
  prop(path_provider, :any, required: true)

  def render(assigns) do
    ~H"""
    <div class="fixed z-1 w-desktop-menu-width h-full pl-10 pt-0 pr-8 md:pt-10 pb-0 md:pb-10 hidden md:block h-full">
      <Menu items={{@items}} path_provider={{@path_provider}} />
    </div>
    """
  end
end
