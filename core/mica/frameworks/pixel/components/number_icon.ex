defmodule Frameworks.Pixel.NumberIcon do
  use MicaWeb, :pixel

  alias Frameworks.Pixel

  attr(:number, :integer, required: true)
  attr(:active, :boolean, default: false)

  def number_icon(assigns) do
    ~H"""
    <Pixel.step_indicator status={if @active, do: :current, else: :incomplete}><%= @number %></Pixel.step_indicator>
    """
  end
end
