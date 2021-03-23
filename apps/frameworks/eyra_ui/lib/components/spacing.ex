defmodule EyraUI.Spacing do
  @moduledoc """
  A line.
  """
  use Surface.Component

  prop(value, :string, required: true)
  prop(direction, :string, default: "t")

  defp spacing("XL", d), do: "m#{d}-12 lg:m#{d}-16"
  defp spacing("L", d), do: "m#{d}-10 lg:m#{d}-12"
  defp spacing("M", d), do: "m#{d}-12 lg:m#{d}-16"
  defp spacing("S", d), do: "m#{d}-8"
  defp spacing("XS", d), do: "m#{d}-4"

  def render(assigns) do
    ~H"""
    <div class="{{spacing(@value, @direction)}}" />
    """
  end
end
