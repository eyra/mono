defmodule EyraUI.Hero.HeroSmall do
  @moduledoc """
  The hero is to be used as a large decorative header with page title.
  """
  use Surface.Component

  prop(title, :string, required: true)
  prop(illustration, :string, default: "/images/illustration.svg")
  prop(text_color, :css_class, default: "text-white")
  prop(bg_color, :css_class, default: "bg-primary")

  def render(assigns) do
    ~H"""
    <div class="flex h-header2 items-center sm:h-header2-sm lg:h-header2-lg {{@text_color}} {{ @bg_color }} overflow-hidden"
         data-native-title={{@title}}>
      <div class="flex-grow flex-shrink-0">
        <p class="text-title5 sm:text-title2 lg:text-title1 font-title1 ml-6 mr-6 lg:ml-14">
          {{@title}}
        </p>
      </div>
      <div class="flex-none h-header2 sm:h-header2-sm lg:h-header2-lg w-illustration sm:w-illustration-sm lg:w-illustration-lg flex-shrink-0">
        <img src={{ @illustration }}/>
      </div>
    </div>
    """
  end
end
