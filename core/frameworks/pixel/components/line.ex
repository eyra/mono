defmodule Frameworks.Pixel.Line do
  @moduledoc """
  A line.
  """
  use CoreWeb, :html

  def line(assigns) do
    ~H"""
    <div class="bg-grey4 h-px" />
    """
  end
end
