defmodule EyraUI.Text.Title2 do
  @moduledoc """
  This title is to be used for ...?
  """
  use Surface.Component

  slot default, required: true

  def render(assigns) do
    ~H"""
    <div class="text-title5 font-title5 sm:text-title3 sm:font-title3 lg:text-title2 lg:font-title2 mt-12 lg:mt-16 mb-7 lg:mb-9">
      <slot />
    </div>
    """
  end
end
