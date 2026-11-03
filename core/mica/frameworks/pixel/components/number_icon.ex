defmodule Frameworks.Pixel.NumberIcon do
  use MicaWeb, :pixel

  alias Frameworks.Pixel.Prism

  attr(:number, :integer, required: true)
  attr(:active, :boolean, default: false)

  def number_icon(assigns) do
    ~H"""
    <Prism.step_indicator status={if @active, do: :current, else: :incomplete}><%= @number %></Prism.step_indicator>
    """
  end
end
