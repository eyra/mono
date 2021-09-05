defmodule EyraUI.Button.Face.Icon do
  @moduledoc """
  A colored button with white text and an icon to the left
  """
  use EyraUI.Component

  prop(vm, :map, required: true)

  defviewmodel(icon: nil)

  def render(assigns) do
    ~H"""
    <div class="active:opacity-80">
      <img src="/images/icons/{{icon(@vm)}}.svg"/>
    </div>
    """
  end
end
