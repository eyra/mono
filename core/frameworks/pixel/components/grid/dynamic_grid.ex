defmodule Frameworks.Pixel.Grid.DynamicGrid do
  @moduledoc false
  use Surface.Component

  @doc "The content"
  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div class="grid lg:grid-cols-2 xl:grid-cols-3 gap-8">
      <slot />
    </div>
    """
  end
end
