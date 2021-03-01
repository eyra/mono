defmodule EyraUI.Text.Title6 do
  @moduledoc """
  This title is to be used for ...?
  """

  use Surface.Component

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div class="text-title6 font-title6 mb-2">
      <slot />
    </div>
    """
  end
end
