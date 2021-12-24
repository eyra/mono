defmodule Frameworks.Pixel.Container.Wrap do
  @moduledoc """
  Container preventing the content to be stretched.
  For example used to keep buttons small when parent div is wider.
  """
  use Surface.Component

  @doc "The content"
  slot(default, required: true)

  def render(assigns) do
    ~F"""
    <div class="flex flex-row">
      <div class="flex-wrap">
        <#slot />
      </div>
    </div>
    """
  end
end
