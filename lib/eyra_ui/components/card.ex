defmodule EyraUI.Card do
  @moduledoc """
  The Unique Selling Point Card highlights a reason for taking an action.
  """
  use Surface.Component

  @doc "The card title"
  slot title
  @doc "The card content, can be button, description etc."
  slot default, required: true

  prop bg_color, :css_class, default: "bg-grey6"
  prop size, :css_class, default: "h-full"

  def render(assigns) do
    ~H"""
    <div class={{ @bg_color, @size, "rounded-md" }}>
      <div class="p-6 lg:pl-8 lg:pr-8 lg:pt-10 lg:pb-10">
        <slot name="title" />
        <slot />
      </div>
    </div>
    """
  end
end
