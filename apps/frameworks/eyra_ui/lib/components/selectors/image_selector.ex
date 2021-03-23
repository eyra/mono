defmodule EyraUI.Selectors.ImageSelector do
  @moduledoc false
  use Surface.Component

  prop(image_url, :string)

  def render(assigns) do
    ~H"""
    <div class="w-image-preview h-image-preview rounded bg-grey4">
      <img class="rounded object-cover w-full h-full" src="{{ @image_url }}" />
    </div>
    """
  end
end
