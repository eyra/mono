defmodule Frameworks.Pixel.Selector.Radio do
  @moduledoc false
  use Frameworks.Pixel.Component

  prop(item, :map, required: true)
  prop(multiselect?, :boolean, default: true)

  def render(assigns) do
    ~F"""
    <div class="flex flex-row gap-3 items-center">
      <div>
        <img x-show="active" src="/images/icons/radio_active.svg" alt={"#{@item.value} is selected"} />
        <img x-show="!active" src="/images/icons/radio.svg" alt={"Select #{@item.value}"} />
      </div>
      <div class=" text-label font-label select-none mt-1">
        {@item.value}
      </div>
    </div>
    """
  end
end
