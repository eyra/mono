defmodule Frameworks.Pixel.Button.SecondaryLiveViewButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop(label, :string, required: true)
  prop(event, :string, required: true)
  prop(color, :css_class, default: "text-delete")
  prop(width, :css_class, default: "pl-4 pr-4")
  prop(target, :any)

  def render(assigns) do
    ~F"""
    <button
      phx-target={@target}
      phx-click={@event}
      class={"pt-13px pb-13px active:pt-14px active:pb-3 active:shadow-top2px border-2 font-button text-button focus:outline-none rounded bg-opacity-0 #{@color} #{@width}"}
    >
      {@label}
    </button>
    """
  end
end
