defmodule CoreWeb.UI.Navigation.DesktopNavbar do
  @moduledoc """
    Horizontal menu used on top of the page
  """
  use CoreWeb.UI.Component

  alias CoreWeb.UI.Navigation.Navbar

  prop(items, :any, required: true)
  prop(path_provider, :any, required: true)
  prop(logo, :any)

  def render(assigns) do
    ~F"""
    <div class="pr-4 flex flex-row gap-4 items-center w-full">
      <div :if={@logo}>
        <img src={"/images/icons/#{@logo}.svg"} alt={"#{@logo}"}>
      </div>
      <div class="flex-grow">
        <Navbar items={@items} path_provider={@path_provider} />
      </div>
    </div>
    """
  end
end
