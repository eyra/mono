defmodule Frameworks.Pixel.Line do
  @moduledoc """
  A line.
  """
  use Surface.Component

  def render(assigns) do
    ~H"""
    <div class="bg-grey4 h-px"></div>
    """
  end
end