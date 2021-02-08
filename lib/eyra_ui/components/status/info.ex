defmodule EyraUI.Status.Info do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component
  alias EyraUI.Status.Status

  prop text, :string, required: true

  def render(assigns) do
    ~H"""
    <Status text={{@text}} text_color="text-success" bg_color="bg-successlight" bg_opacity="bg-opacity-100" />
    """
  end
end
