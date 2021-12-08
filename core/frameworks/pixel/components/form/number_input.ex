defmodule Frameworks.Pixel.Form.NumberInput do
  @moduledoc false
  use Surface.Component
  alias Frameworks.Pixel.Form.Input

  prop(field, :atom, required: true)
  prop(label_text, :string)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, default: :light)
  prop(debounce, :string, default: "1000")

  def render(assigns) do
    ~H"""
      <Input field={{@field}} label_text={{@label_text}} label_color={{@label_color}} background={{@background}} debounce={{@debounce}} type="number" />
    """
  end
end
