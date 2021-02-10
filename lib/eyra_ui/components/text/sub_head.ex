defmodule EyraUI.Text.SubHead do
  @moduledoc """
  This subhead is to be used for ...?
  """

  use Surface.Component

  slot default, required: true

  def render(assigns) do
    ~H"""
    <div class="text-intro lg:text-subhead font-subhead mb-4 lg:mb-9 text-grey2 tracking-wider">
      <slot />
    </div>
    """
  end
end
