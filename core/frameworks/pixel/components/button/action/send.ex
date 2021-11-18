defmodule Frameworks.Pixel.Button.Action.Send do
  @moduledoc """
  Sends phoenix event to target (live component or live view)
  """
  use Frameworks.Pixel.Component

  prop(vm, :map, required: true)

  defviewmodel(
    event: nil,
    item: "",
    target: ""
  )

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div phx-target={{target(@vm)}} phx-click={{ event(@vm) }} phx-value-item={{item(@vm)}} class="cursor-pointer focus:outline-none">
      <slot />
    </div>
    """
  end
end
