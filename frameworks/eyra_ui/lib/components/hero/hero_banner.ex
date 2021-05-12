defmodule EyraUI.Hero.HeroBanner do
  @moduledoc """
  The hero is to be used as a large decorative header with image, title and subtitle.
  """
  use Surface.Component

  alias EyraUI.Icon
  alias EyraUI.Text.{Title4}

  prop(title, :string, required: true)
  prop(subtitle, :string, required: true)
  prop(icon_url, :string, required: true)
  prop(illustration, :string, default: "/images/illustration2.svg")
  prop(bg_color, :css_class, default: "bg-grey1")

  def render(assigns) do
    ~H"""
    <div class="relative overflow-hidden w-full h-24 sm:h-32 lg:h-44 {{@bg_color}}">
      <div class="flex h-full items-center">
        <div class="flex-wrap ml-6 sm:ml-14 {{@bg_color}} bg-opacity-50 z-20 rounded-lg">
          <div class="flex items-center">
            <div class="">
              <Icon size="L" src={{ @icon_url }} border_size="border-2"/>
            </div>
            <div class="ml-6 mr-4 sm:ml-8">
              <Title4 color="text-white">
                <div>{{@title}}</div>
                <div class="mb-1"></div>
                <div>{{@subtitle}}</div>
              </Title4>
            </div>
          </div>
        </div>
        <div class="absolute z-10 bottom-0 right-0 object-scale-down flex-wrap h-full flex-shrink-0">
          <img class="object-scale-down h-full" src={{ @illustration }}/>
        </div>
      </div>
    </div>
    """
  end
end
