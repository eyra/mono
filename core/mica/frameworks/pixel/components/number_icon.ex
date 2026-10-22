defmodule Frameworks.Pixel.NumberIcon do
  use CoreWeb, :pixel

  defp prism_class(true), do: "prism-number-icon-active"
  defp prism_class(false), do: "prism-number-icon-inactive"

  attr(:number, :integer, required: true)
  attr(:active, :boolean, default: false)

  def number_icon(assigns) do
    assigns = assign(assigns, :prism_class, prism_class(assigns.active))

    ~H"""
    <span class={"prism-number-icon #{@prism_class}"}><%= @number %></span>
    """
  end
end
