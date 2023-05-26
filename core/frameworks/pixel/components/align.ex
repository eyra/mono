defmodule Frameworks.Pixel.Align do
  @moduledoc """
  Centers content along the x-axis.
  """
  use CoreWeb, :html

  slot(:inner_block, required: true)

  def horizontal_center(assigns) do
    ~H"""
    <div class="flex flex-row items-center justify-center w-full h-full">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  slot(:inner_block, required: true)

  def vertical_center(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center w-full">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
