defmodule EyraUI.Grid.AbsoluteGrid do
  use Surface.Component

  @doc "The content"
  slot default, required: true

  def render(assigns) do
    ~H"""
    <div class="grid md:grid-cols-3 gap-8 ml-6 mr-6 lg:ml-14 lg:mr-14">
      <slot />
    </div>
    """
  end
end
