defmodule EyraUI.Button.DynamicButton do
  use EyraUI.Component

  alias EyraUI.Button.{DynamicAction, DynamicFace}

  prop(vm, :string, required: true)

  defviewmodel(
    action: nil,
    face: nil
  )

  def render(assigns) do
    ~H"""
    <DynamicAction vm={{action(@vm)}}>
      <DynamicFace vm={{face(@vm)}} />
    </DynamicAction>
    """
  end
end
