defmodule Frameworks.Pixel.Grid.ImageGrid do
  @moduledoc false
  use Surface.Component

  prop(gap, :string, default: "gap-4 sm:gap-10")

  @doc "The content"
  slot(default, required: true)

  def render(assigns) do
    ~F"""
    <div class={"grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 #{@gap}"}>
      <#slot />
    </div>
    """
  end
end

defmodule Frameworks.Pixel.Grid.ImageGrid.Image do
  @moduledoc false
  use Frameworks.Pixel.Component

  defviewmodel(
    id: nil,
    url: nil,
    srcset: nil,
    index: nil,
    target: ""
  )

  prop(vm, :any, required: true)

  def render(assigns) do
    ~F"""
      <div
        id={"clickable-area-#{index(@vm)}"}
        class="relative bg-grey4 ring-4 hover:ring-primary cursor-pointer rounded overflow-hidden"
        :class={"{ 'ring-primary': selected === #{index(@vm)}, 'ring-white': selected != #{index(@vm)} }"}
        x-on:click={"selected = #{index(@vm)}"}
        :on-click="select_image"
        phx-value-image={id(@vm)}
        phx-target={target(@vm)}
      >
        <div
          class="absolute z-10 w-full h-full bg-primary bg-opacity-50"
          :class={"{ 'visible': selected === #{index(@vm)}, 'invisible': selected != #{index(@vm)} }"}
        />
        <div
          class="absolute z-20 w-full h-full"
          :class={"{ 'visible': selected === #{index(@vm)}, 'invisible': selected != #{index(@vm)} }"}
        >
          <img class="w-full h-full object-none" src="/images/checkmark.svg" alt="" />
        </div>
        <div class="w-full h-full">
          <img class="object-cover w-full h-full image" src={url(@vm)} srcset={srcset(@vm)}/>
        </div>
      </div>
    """
  end
end
