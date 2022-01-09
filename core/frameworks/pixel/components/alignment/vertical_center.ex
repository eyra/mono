defmodule Frameworks.Pixel.Alignment.VerticalCenter do
  @moduledoc """
  Centers content along the x-axis.
  """
  use Surface.Component

  @doc "The content"
  slot(default, required: true)

  def render(assigns) do
    ~F"""
    <div class="flex flex-col items-center justify-center w-full">
      <#slot />
    </div>
    """
  end
end
