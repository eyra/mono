defmodule Frameworks.Pixel.Wrap do
  @moduledoc """
    Wraps an element.
  """
  use Surface.Component

  slot(default)

  def render(assigns) do
    ~H"""
      <div class="flex flex-row">
        <div class="flex-wrap">
          <slot />
        </div>
      </div>
    """
  end
end
