defmodule Frameworks.Pixel.Wrap do
  @moduledoc """
    Wraps an element x.
  """
  use Surface.Component

  slot(default)

  def render(assigns) do
    ~F"""
    <div class="flex flex-row">
      <div class="flex-wrap">
        <#slot />
      </div>
    </div>
    """
  end
end
