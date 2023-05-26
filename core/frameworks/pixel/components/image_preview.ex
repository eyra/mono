defmodule Frameworks.Pixel.ImagePreview do
  @moduledoc false
  use CoreWeb, :html

  attr(:image_url, :string)
  attr(:placeholder, :string, required: true)

  attr(:shape, :string,
    default: "w-image-preview sm:w-image-preview-sm h-image-preview sm:h-image-preview-sm rounded"
  )

  def image_preview(assigns) do
    ~H"""
    <div class={"overflow-hidden bg-grey4 border-2 border-grey4 #{@shape}"}>
      <img
        class="object-cover w-full h-full"
        src={"#{if @image_url do
          @image_url
        else
          @placeholder
        end}"}
        alt="Image preview"
      />
    </div>
    """
  end
end
