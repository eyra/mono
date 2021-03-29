defmodule EyraUI.ImagePreview do
  @moduledoc false
  use Surface.Component

  prop(image_url, :string)

  def render(assigns) do
    ~H"""
    <div class="w-image-preview h-image-preview rounded overflow-hidden bg-grey4">
      <img class="object-cover w-full h-full" src="{{ @image_url }}" />
    </div>
    """
  end
end
