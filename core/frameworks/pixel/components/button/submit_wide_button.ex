defmodule Frameworks.Pixel.Button.SubmitWideButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop(label, :string, required: true)
  prop(bg_color, :css_class, default: "bg-primary")

  def render(assigns) do
    ~F"""
    <button
      class={"w-full pt-15px pb-15px active:pt-4 active:pb-14px active:shadow-top4px leading-none font-button text-button text-white focus:outline-none rounded pr-4 pl-4 #{@bg_color}"}
      type="submit"
    >
      {@label}
    </button>
    """
  end
end
