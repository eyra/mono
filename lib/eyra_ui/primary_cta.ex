defmodule EyraUI.PrimaryCTA do
  @moduledoc """
  A large eye-catcher meant to call a user into taking an action.
  """
  use Surface.Component

  prop title, :string, required: true
  prop button_label, :string, required: true
  prop to, :string, required: true
  prop bg_color, :css_class, default: "bg-grey1"
  prop button_bg_color, :css_class, default: "bg-white"

  def render(assigns) do
    ~H"""
    <div class={{ @bg_color, "w-full", "rounded-md" }}>
    <div class="p-6 lg:pl-8 lg:pr-8 lg:pt-10 lg:pb-10">
        <div class="text-white text-title5 font-title5 lg:text-title3 lg:font-title3">
            {{ @title }}
        </div>
        <div class="mt-6 lg:mt-8">
            <div class="flex items-center">
                <div class="flex-wrap">
                    <a href={{ @to }}>
                        <div class={{"flex", "items-center", "hover:bg-opacity-80", "focus:outline-none", "pl-4", "pr-4", "h-48px", "font-button", "text-button", "text-primary", "tracker-widest", "rounded",
                                    @button_bg_color}}>
                            <div>{{ @button_label }}</div>
                        </div>
                    </a>
                </div>
                <div class="flex-grow"></div>
            </div>
        </div>
    </div>
    </div>
    """
  end
end
