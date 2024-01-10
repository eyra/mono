defmodule Frameworks.Pixel.Image do
  use CoreWeb, :html

  attr(:id, :any, required: true)
  attr(:image, :any, required: true)
  attr(:corners, :string, default: "")
  attr(:transition, :string, default: "duration-500")
  attr(:string, :string, default: "")

  @doc """
  An image with fancy features like blur-hash.
  """
  def blurhash(assigns) do
    canvas_width = 32

    canvas_height =
      if assigns.image do
        floor(assigns.image.height / (assigns.image.width / 32))
      else
        32
      end

    assigns =
      assign(assigns, %{
        canvas_width: canvas_width,
        canvas_height: canvas_height
      })

    ~H"""
    <%= if @image do %>
      <div
        id={@id}
        class="blurhash-wrapper overflow-hidden w-full h-full relative"
        x-data="blurHash()"
        x-init="$nextTick(()=>render())"
      >
        <canvas
          x-show="showBlurHash()"
          x-transition:leave="transition ease-in-out duration-500"
          x-transition:leave-start="opacity-100"
          x-transition:leave-end="opacity-0"
          width={@canvas_width}
          height={@canvas_height}
          class={"absolute z-10 object-cover w-full h-full #{@corners}"}
          data-blurhash={@image.blur_hash}
        />
        <img
          class={"object-cover w-full h-full #{@corners}"}
          src={@image.url}
          srcset={@image.srcset}
          loading="lazy"
          x-on:load="hideBlurHash()"
          alt=""
        />
      </div>
    <% end %>
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
