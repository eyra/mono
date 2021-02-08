defmodule EyraUI.Button.SecondaryLiveViewButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop label, :string, required: true
  prop event, :string, required: true
  prop color, :css_class, default: "bg-white"
  prop border_color, :css_class, default: "border-delete"
  prop border_width, :css_class, default: "border-2"
  prop width, :css_class, default: "pl-4 pr-4"
  prop margin, :css_class, default: "mr-4"

  def render(assigns) do
    ~H"""
    <button phx-click={{ @event }} class="h-11 ring-2 ring-delete font-button text-button text-delete focus:outline-none hover:opacity-80 rounded {{@color}} {{@width}} {{@margin}}">
      {{@label}}
    </button>
    """
  end
end
