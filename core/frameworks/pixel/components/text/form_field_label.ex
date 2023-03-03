defmodule Frameworks.Pixel.Text.FormFieldLabel do
  @moduledoc """
  This label is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(id, :any, required: true)
  prop(color, :css_class, default: "text-grey1")

  def render(assigns) do
    ~F"""
    <div id={@id} class={"mt-0.5 text-title6 font-title6 leading-snug  #{@color}"}>
      <#slot />
    </div>
    """
  end
end
