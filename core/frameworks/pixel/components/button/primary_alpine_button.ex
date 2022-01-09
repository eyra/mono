defmodule Frameworks.Pixel.Button.PrimaryAlpineButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop(label, :string, required: true)
  prop(click, :string, required: true)
  prop(bg_color, :css_class, default: "bg-primary")
  prop(text_color, :css_class, default: "text-white")

  def render(assigns) do
    ~F"""
    <button @click={@click} class={"pt-15px pb-15px active:shadow-top4px active:pt-4 active:pb-14px leading-none font-button text-button focus:outline-none rounded pr-4 pl-4 #{@bg_color} #{@text_color}"} type="button">
      {@label}
    </button>
    """
  end
end
