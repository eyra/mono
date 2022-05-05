defmodule Frameworks.Pixel.Form.DateInput do
  @moduledoc false
  use Surface.Component
  alias Frameworks.Pixel.Form.Input

  prop(field, :atom, required: true)
  prop(label_text, :string)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, default: :light)
  prop(disabled, :boolean, default: false)
  prop(value, :string)

  def render(assigns) do
    ~F"""
      <Input field={@field} label_text={@label_text} label_color={@label_color} background={@background} type="date" disabled={@disabled} debounce={nil} value={@value}/>
    """
  end
end
