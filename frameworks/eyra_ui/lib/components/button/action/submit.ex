defmodule EyraUI.Button.Action.Submit do
  @moduledoc """
  Submits form and optionally triggers alpine functionality on top of that
  """
  use Surface.Component

  prop(alpine_code, :string)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <button @click={{@alpine_code}} type="submit" class="focus:outline-none">
      <slot />
    </button>
    """
  end
end
