defmodule EyraUI.Container.FormArea do
  @moduledoc """
  Container for displaying horizontally centralized forms.
  """
  use Surface.Component

  @doc "The form content"
  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div class="flex justify-center">
      <div class="flex-grow sm:max-w-form">
        <slot />
      </div>
    </div>
    """
  end
end
