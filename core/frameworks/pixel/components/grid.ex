defmodule Frameworks.Pixel.Grid do
  @moduledoc false
  use CoreWeb, :html

  slot(:inner_block, required: true)

  def dynamic(assigns) do
    ~H"""
    <div class="grid lg:grid-cols-2 xl:grid-cols-3 gap-8">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  slot(:inner_block, required: true)

  def absolute(assigns) do
    ~H"""
    <div class="grid md:grid-cols-3 gap-8">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:gap, :string, default: "gap-4 sm:gap-10")
  slot(:inner_block, required: true)

  def image(assigns) do
    ~H"""
    <div class={"grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 #{@gap}"}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
