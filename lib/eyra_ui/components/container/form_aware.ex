defmodule EyraUI.Container.FormAware
 do
  @moduledoc """
  Container for displaying horizontally centralized forms.
  """
  use Surface.Component

  @doc "The form content"
  slot default, required: true

  def render(assigns) do
    ~H"""
    <div class="flex justify-center">
      <div class="flex-grow max-w-form ml-6 mr-6 lg:m-0 mt-6 sm:mt-16 lg:mt-24">
        <slot />
      </div>
    </div>
    """
  end
end
