defmodule EyraUI.Alignment.HorizontalCenter do
  @moduledoc """
  Centers content along the x-axis.
  """
  use Surface.Component

  @doc "The content"
  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div class="flex flex-row items-center justify-center h-full">
      <slot />
    </div>
    """
  end
end
