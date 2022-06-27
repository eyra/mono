defmodule Frameworks.Pixel.Status.Info do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component
  alias Frameworks.Pixel.Status.Status

  prop(text, :string, required: true)

  def render(assigns) do
    ~F"""
    <Status
      text={@text}
      text_color="text-success"
      bg_color="bg-successlight"
      bg_opacity="bg-opacity-100"
    />
    """
  end
end
