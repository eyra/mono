defmodule EyraUI.Hero.HeroLarge do
  @moduledoc """
  The hero is to be used as a large decorative header with page title.
  """
  use Surface.Component

  prop title, :string, required: true
  prop subtitle, :string, required: true
  prop illustration, :string, default: "/images/illustration.svg"
  prop size, :string, default: "large"
  prop text_color, :css_class, default: "text-white"
  prop bg_color, :css_class, default: "bg-primary"

  def render(assigns) do
    ~H"""
    <div class={{"flex", "h-header1", "items-center", "sm:h-header1-sm", "lg:h-header1-lg", "mb-9", "lg:mb-16", @text_color,  @bg_color }}>
      <div class="flex-grow flex-shrink-0">
        <p class="text-title5 sm:text-title2 lg:text-title1 font-title1 ml-6 mr-6 lg:ml-14">
          {{ @title }}<br>{{ @subtitle }}
        </p>
      </div>
      <div class="flex-none w-illustration sm:w-illustration-sm lg:w-illustration-lg flex-shrink-0">
        <img src={{ @illustration }}/>
      </div>
    </div>
    """
  end
end
