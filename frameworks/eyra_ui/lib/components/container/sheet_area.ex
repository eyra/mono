defmodule EyraUI.Container.SheetArea do
  @moduledoc """
  Container for displaying horizontally centralized forms.
  """
  use Surface.Component

  prop(top_padding, :css_class, default: "pt-6 md:pt-9 lg:pt-14")

  @doc "The form content"
  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div class="flex justify-center {{ @top_padding }}">
      <div class="flex-grow sm:max-w-sheet">
        <slot />
      </div>
    </div>
    """
  end
end
