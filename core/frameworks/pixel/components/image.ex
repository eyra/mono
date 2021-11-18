defmodule Frameworks.Pixel.Image do
  @moduledoc """
  An image with fancy features like blur-hash.
  """
  use Surface.Component

  prop(image, :any, required: true)
  prop(corners, :css_class, default: "")
  prop(transition, :css_class, default: "duration-500")
  prop(css_class, :css_class, default: "")

  def render(assigns) do
    canvas_width = 32

    canvas_height =
      if assigns.image do
        floor(assigns.image.height / (assigns.image.width / 32))
      else
        32
      end

    ~H"""
    <div id={{ @image.url }}
      class="blurhash-wrapper overflow-hidden w-full h-full relative"
      x-data="blurHash()"
      x-init="$nextTick(()=>render())"
      :if={{@image}}
      >
      <canvas
        x-show="showBlurHash()"
        x-transition:leave="transition ease-in-out duration-500"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0"
        width={{canvas_width}}
        height={{canvas_height}}
        class={{"absolute", "z-10", "object-cover", "w-full", "h-full", @corners}}
        data-blurhash={{@image.blur_hash}}
        />
      <img
        class={{"object-cover", "w-full", "h-full", @corners}}
        src={{ @image.url }}
        srcset={{@image.srcset}}
        loading="lazy"
        x-on:load="hideBlurHash()"
        alt=""
      />
    </div>
    """
  end
end
