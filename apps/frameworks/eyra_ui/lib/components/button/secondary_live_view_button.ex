defmodule EyraUI.Button.SecondaryLiveViewButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop(label, :string, required: true)
  prop(event, :string, required: true)
  prop(color, :css_class, default: "bg-white")
  prop(width, :css_class, default: "pl-4 pr-4")

  def render(assigns) do
    ~H"""
    <div class="">
    <button phx-click={{ @event }} class="pt-13px pb-13px active:pt-14px active:pb-3 active:shadow-top2px border-2 border-delete font-button text-button text-delete focus:outline-none rounded {{@color}} {{@width}}">
      {{@label}}
    </button>
    </div>
    """
  end
end
