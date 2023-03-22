defmodule Frameworks.Pixel.SquareContainer do
  use Surface.Component

  slot(default, required: true)

  def render(assigns) do
    ~F"""
    <div class="relative rounded-lg bg-grey6 h-248px">
      <div class="absolute top-0 left-0 w-full flex flex-row gap-6 p-6 overflow-scroll scrollbar-hide">
        <#slot />
      </div>
      <div class="absolute top-0 right-0 h-full w-64px rounded-tr-lg rounded-br-lg bg-gradient-to-r from-white to-black opacity-5" />
    </div>
    """
  end
end
