defmodule Frameworks.Pixel.Image do
  use CoreWeb, :pixel

  attr(:id, :any, required: true)
  attr(:image, :any, required: true)
  attr(:style, :string, default: "fixed")

  @doc """
  An image with fancy features like blur-hash.
  """
  def blurhash(%{image: %{height: height, width: width}} = assigns)
      when not is_nil(height) and not is_nil(width) do
    src = Map.get(assigns.image, :url, "")
    srcset = Map.get(assigns.image, :srcset, "")
    blur_hash = Map.get(assigns.image, :blur_hash, "")

    assigns =
      assign(assigns, %{
        src: src,
        srcset: srcset,
        blur_hash: blur_hash
      })

    ~H"""
      <div
        id={@id}
        phx-hook="Blurhash"
        phx-update="ignore"
        data-blurhash={@blur_hash}
        data-image-width={@image.width}
        data-image-height={@image.height}
        data-style={@style}
        data-src={@src}
        class={"overflow-hidden w-full h-full relative"}
      />
    """
  end

  attr(:id, :any, required: true)
  attr(:url, :any, required: true)
  attr(:srcset, :string, required: true)
  attr(:index, :string, required: true)
  attr(:target, :string, default: "")
  attr(:selected, :boolean, default: false)

  @doc """
  An image that can be used in an image grid.
  """
  def grid(assigns) do
    ~H"""
    <div
      id={"clickable-area-#{@index}"}
      class={"relative bg-grey5 h-full outline outline-4 hover:outline-primary cursor-pointer rounded overflow-hidden #{if @selected do "outline-primary" else "outline-grey5" end}"}
      phx-click="select_image"
      phx-value-image={@id}
      phx-target={@target}
    >
      <div
        class={"absolute z-10 w-full h-full bg-primary bg-opacity-50 #{if @selected do "visible" else "invisible" end}"}
      />
      <div
        class={"absolute z-20 w-full h-full #{if @selected do "visible" else "invisible" end}"}
      >
        <img class="w-full h-full object-none" src={~p"/images/checkmark.svg"} alt="">
      </div>
      <div class="w-full h-full">
        <img id={@id} class="object-cover w-full h-full image" src={@url} srcset={@srcset}>
      </div>
    </div>
    """
  end

  attr(:image_url, :string)
  attr(:placeholder, :string, required: true)

  attr(:shape, :string,
    default: "w-image-preview sm:w-image-preview-sm h-image-preview sm:h-image-preview-sm rounded"
  )

  def preview(assigns) do
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
