defmodule Frameworks.Pixel.Button.Action.Toggle do
  @moduledoc """
  Triggers js code after click to show specified div
  """
  use Frameworks.Pixel.Component

  prop(vm, :map, required: true)

  defviewmodel(
    id: nil,
    target: nil
  )

  slot(default, required: true)

  def render(assigns) do
    ~F"""
    <div
      id={id(@vm)}
      phx-hook="Toggle"
      target={target(@vm)}
      class="cursor-pointer focus:outline-none"
    >
      <#slot />
    </div>
    """
  end
end
