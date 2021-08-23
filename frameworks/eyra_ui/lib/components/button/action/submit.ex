defmodule EyraUI.Button.Action.Submit do
  @moduledoc """
  Submits form and optionally triggers alpine functionality on top of that
  """
  use EyraUI.Component

  prop(vm, :map, required: true)

  defviewmodel(code: nil)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <button @click={{code(@vm)}} type="submit" class="cursor-pointer focus:outline-none">
      <slot />
    </button>
    """
  end
end
