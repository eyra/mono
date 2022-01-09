defmodule Frameworks.Pixel.Button.Action.Click do
  @moduledoc """
  Triggers alpine code after click
  """
  use Frameworks.Pixel.Component

  prop(vm, :map, required: true)

  defviewmodel(code: nil)

  slot(default, required: true)

  def render(assigns) do
    ~F"""
    <div x-on:click={code(@vm)} class="cursor-pointer focus:outline-none">
      <#slot />
    </div>
    """
  end
end
