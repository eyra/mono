defmodule Frameworks.Pixel.Form.UrlInput do
  @moduledoc false
  use Surface.Component
  alias Frameworks.Pixel.Form.Input

  prop(field, :atom, required: true)
  prop(label_text, :string)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, default: :light)
  slot(default)

  def render(assigns) do
    ~H"""
    <Input  field={{@field}} label_text={{@label_text}} label_color={{@label_color}} background={{@background}} type="url" >
      <slot />
    </Input>
    """
  end
end
