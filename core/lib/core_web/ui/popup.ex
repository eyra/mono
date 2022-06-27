defmodule CoreWeb.UI.Popup do
  use CoreWeb.UI.Component

  slot(default)

  def render(assigns) do
    ~F"""
    <div class="fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-20">
      <div class="flex flex-row items-center justify-center w-full h-full">
        <#slot />
      </div>
    </div>
    """
  end
end
