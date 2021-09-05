defmodule EyraUI.Button.Action.Click do
  @moduledoc """
  Triggers alpine code after click
  """
  use EyraUI.Component

  prop(vm, :map, required: true)

  defviewmodel(code: nil)

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div x-on:click={{code(@vm)}} class="cursor-pointer focus:outline-none">
      <slot />
    </div>
    """
  end
end
