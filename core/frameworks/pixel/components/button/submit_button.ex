defmodule Frameworks.Pixel.Button.SubmitButton do
  @moduledoc """
  A colored button with white text
  """
  use Surface.Component

  prop(label, :string, required: true)
  prop(bg_color, :css_class, default: "bg-primary")
  prop(alpine_onclick, :string)
  prop(target, :string)

  def render(assigns) do
    ~F"""
    <button
      x-on:click={@alpine_onclick}
      class={"pt-15px pb-15px active:pt-4 active:pb-14px active:shadow-top4px leading-none font-button text-button text-white focus:outline-none rounded pr-4 pl-4 #{@bg_color}"}
      type="submit"
      phx-target={@target}
    >
      {@label}
    </button>
    """
  end
end
