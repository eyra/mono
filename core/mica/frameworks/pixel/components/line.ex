defmodule Frameworks.Pixel.Line do
  @moduledoc """
  A line.
  """
  use MicaWeb, :pixel

  attr(:color, :string, default: "bg-grey4")
  attr(:height, :string, default: "h-px")

  def line(assigns) do
    ~H"""
    <div class={"#{@color} #{@height}"} />
    """
  end
end
