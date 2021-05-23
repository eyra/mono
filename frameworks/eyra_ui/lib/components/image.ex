defmodule EyraUI.Image do
  @moduledoc """
  An image with fancy features like blur-hash.
  """
  use Surface.Component
  prop(image, :any, required: true)
  prop(class, :css_class, required: false)

  def render(assigns) do
    canvas_width = 32
    canvas_height = floor(assigns.image.height / (assigns.image.width / 32))

    ~H"""
    <div  
    class="blurhash-wrapper"
    x-data="blurHash()"
        x-init="render()">
    <canvas 
        x-show="showBlurHash()" 
        x-transition:leave="transition ease-in-out duration-300"
        x-transition:leave-start="opacity-100"
        x-transition:leave-end="opacity-0" 
    width={{canvas_width}} 
    height={{canvas_height}} 
    class={{"absolute", "z-10", @class}}
    data-blurhash={{@image.blur_hash}}
    />
    <img class={{@class}} src={{ @image.url }} 
    srcset={{@image.srcset}} 
    width={{@image.width}} 
    height={{@image.height}} 
    loading="lazy" 
    x-on:load="hideBlurHash()" 
    />
    </div>
    """
  end
end
