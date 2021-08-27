defmodule EyraUI.ImagePreview do
  @moduledoc false
  use Surface.Component

  prop(image_url, :string)
  prop(placeholder, :string, required: true)

  prop(shape, :string,
    default: "w-image-preview sm:w-image-preview-sm h-image-preview sm:h-image-preview-sm rounded"
  )

  def render(assigns) do
    ~H"""
    <div class="overflow-hidden bg-grey4 border-2 border-grey4 {{@shape}}">
      <img class="object-cover w-full h-full" src="{{ if @image_url do @image_url else @placeholder end }}" />
    </div>
    """
  end
end
