defmodule EyraUI.Button.PrimaryLiveViewButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop(label, :string, required: true)
  prop(event, :string, required: true)
  prop(width, :css_class, default: "pl-4 pr-4")
  prop(target, :any)

  def render(assigns) do
    ~H"""
    <button phx-target={{@target}} phx-click={{ @event }} class="pt-15px pb-15px active:pt-4 active:pb-14px active:shadow-top4px leading-none font-button text-button text-white focus:outline-none rounded bg-primary {{@width}}">
      {{ @label }}
    </button>
    """
  end
end
