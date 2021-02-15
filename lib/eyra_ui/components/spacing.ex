defmodule EyraUI.Spacing do
  @moduledoc """
  A line.
  """
  use Surface.Component

  prop value, :number, required: true

  defp spacing("XL"), do: "mt-12 lg:mt-16"
  defp spacing("L"), do: "mt-10 lg:mt-12"
  defp spacing("M"), do: "mt-12 lg:mt-16"
  defp spacing("S"), do: "mt-8"

  def render(assigns) do
    ~H"""
    <div class="{{spacing(@value)}}" />
    """
  end
end
