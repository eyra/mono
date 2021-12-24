defmodule Frameworks.Pixel.Spacing do
  @moduledoc """
  A line.
  """
  use Surface.Component

  prop(value, :string, required: true)
  prop(direction, :string, default: "t")

  defp spacing("XXL", "t"), do: "mt-16 lg:mt-24"
  defp spacing("XL", "t"), do: "mt-12 lg:mt-16"
  defp spacing("L", "t"), do: "mt-10 lg:mt-12"
  defp spacing("M", "t"), do: "mt-8"
  defp spacing("S", "t"), do: "mt-6"
  defp spacing("XS", "t"), do: "mt-4"
  defp spacing("XXS", "t"), do: "mt-2"

  defp spacing("XXL", "l"), do: "ml-16 lg:ml-20"
  defp spacing("XL", "l"), do: "ml-12 lg:ml-16"
  defp spacing("L", "l"), do: "ml-10 lg:ml-12"
  defp spacing("M", "l"), do: "ml-8"
  defp spacing("S", "l"), do: "ml-6"
  defp spacing("XS", "l"), do: "ml-4"
  defp spacing("XXS", "l"), do: "ml-2"

  def render(assigns) do
    ~F"""
    <div class={"#{spacing(@value, @direction)}"} />
    """
  end
end
