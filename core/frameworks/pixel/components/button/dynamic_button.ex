defmodule Frameworks.Pixel.Button.DynamicButton do
  use Frameworks.Pixel.Component

  alias Frameworks.Pixel.Button.{DynamicAction, DynamicFace}

  prop(vm, :string, required: true)

  defviewmodel(
    action: nil,
    face: nil
  )

  def render(assigns) do
    ~F"""
    <DynamicAction vm={action(@vm)}>
      <DynamicFace vm={face(@vm)} />
    </DynamicAction>
    """
  end
end
