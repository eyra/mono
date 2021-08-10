defmodule EyraUI.Button.Action.Click do
  @moduledoc """
  Triggers alpine code after click
  """
  use Surface.Component

  prop(code, :string, required: true)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <button @click={{@code}} type="button" class="focus:outline-none">
      <slot />
    </button>
    """
  end
end
