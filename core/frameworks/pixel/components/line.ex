defmodule Frameworks.Pixel.Line do
  @moduledoc """
  A line.
  """
  use CoreWeb, :pixel

  attr(:color, :string, default: "bg-grey4")
  attr(:height, :string, default: "h-px")

  def line(assigns) do
    ~H"""
    <div class={"#{@color} #{@height}"} />
    """
  end
end
