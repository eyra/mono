defmodule Frameworks.Pixel.Form.Field do
  @moduledoc false
  use Surface.Component
  alias Frameworks.Pixel.Form.{Label}
  alias Frameworks.Pixel.Spacing
  alias Frameworks.Pixel.Form.ValidationErrors

  prop(form, :form, required: true)
  prop(field, :atom, required: true)
  prop(label_text, :string)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, required: true)
  prop(change, :event)
  prop(read_only, :boolean, default: false)
  prop(reserve_error_space, :boolean, default: true)
  prop(extra_space, :boolean, default: true)
  slot(default)

  def render(assigns) do
    ~H"""
    <div :if={{ @label_text }}>
      <Label form={{@form}} field={{@field}} label_text={{@label_text}} label_color={{@label_color}} background={{@background}} />
      <Spacing value="XXS" />
    </div>
    <slot />
    <Spacing :if={{ @extra_space }} value="XXS" />
    <ValidationErrors form={{@form}} field={{@field}} reserve_error_space={{@reserve_error_space}}/>
    """
  end
end
