defmodule Frameworks.Pixel.Form.TextInput do
  @moduledoc false
  use Surface.Component
  alias Frameworks.Pixel.Form.Input

  prop(field, :atom, required: true)
  prop(label_text, :string)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, default: :light)
  prop(placeholder, :string, default: "")
  prop(debounce, :string, default: "1000")

  def render(assigns) do
    ~F"""
      <Input field={@field} label_text={@label_text} label_color={@label_color} background={@background} placeholder={@placeholder} debounce={@debounce} type="text" />
    """
  end
end
