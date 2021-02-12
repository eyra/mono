defmodule EyraUI.Button.PrimaryLiveViewButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop label, :string, required: true
  prop event, :string, required: true
  prop width, :css_class, default: "pl-4 pr-4"
  prop margin, :css_class, default: "mr-4"

  def render(assigns) do
    ~H"""
    <button phx-click={{ @event }} class="h-48px leading-none font-button text-button text-white focus:outline-none hover:opacity-80 rounded bg-primary {{@width}} {{@margin}}">
      {{ @label }}
    </button>
    """
  end
end
