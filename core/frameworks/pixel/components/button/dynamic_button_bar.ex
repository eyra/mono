defmodule Frameworks.Pixel.Button.DynamicButtonBar do
  use Frameworks.Pixel.Component

  alias Frameworks.Pixel.Button.DynamicButton

  prop(buttons, :list, required: true)

  def render(assigns) do
    ~F"""
    <div class="flex flex-row gap-4">
      <DynamicButton :for={button <- @buttons} vm={button} />
    </div>
    """
  end
end
