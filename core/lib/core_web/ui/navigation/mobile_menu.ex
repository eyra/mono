defmodule CoreWeb.UI.Navigation.MobileMenu do
  @moduledoc """
    Vertical stacked menu used on the side
  """
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Navigation.Menu

  prop(items, :any, required: true)
  prop(path_provider, :any, required: true)

  def render(assigns) do
    ~F"""
    <div class="md:hidden bg-white p-6 h-full">
      <Menu items={@items} path_provider={@path_provider} />
    </div>
    """
  end
end
