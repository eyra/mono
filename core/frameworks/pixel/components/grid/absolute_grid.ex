defmodule Frameworks.Pixel.Grid.AbsoluteGrid do
  @moduledoc """
  The grid is to be used for.
  """
  use Surface.Component

  @doc "The content"
  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div class="grid md:grid-cols-3 gap-8">
      <slot />
    </div>
    """
  end
end
