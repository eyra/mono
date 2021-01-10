defmodule EyraUI.USPCard do
  @moduledoc """
  The Unique Selling Point Card highlights a reason for taking an action.
  """
  use Surface.Component

  prop title, :string, required: true
  prop description, :string, required: true
  prop title_color, :css_class, default: "text-grey1"
  prop description_color, :css_class, default: "text-grey2"
  prop bg_color, :css_class, default: "bg-grey6"

  def render(assigns) do
    ~H"""
    <div class={{ @bg_color, "h-full", "rounded-md" }}>
      <div class="p-6 lg:pl-8 lg:pr-8 lg:pt-10 lg:pb-10">
        <div class={{"text-title5", "font-title5", "lg:text-title4", "lg:font-title4", "mb-4", "lg:mb-6", @title_color }}>
            {{ @title }}
        </div>
        <div class={{ "text-bodysmall", "lg:text-bodymedium", "font-body", @description_color }}>
            {{ @description }}
        </div>
      </div>
    </div>
    """
  end
end
