defmodule EyraUI.Text.Intro do
  @moduledoc """
  The intro is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)

  def render(assigns) do
    ~H"""
    <div class="text-intro lg:text-introdesktop font-intro lg:mb-9">
      <slot />
    </div>
    """
  end
end
