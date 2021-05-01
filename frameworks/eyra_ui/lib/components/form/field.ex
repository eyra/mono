defmodule EyraUI.Form.Field do
  @moduledoc false
  use Surface.Component
  alias EyraUI.Form.{Label}
  alias EyraUI.Spacing
  alias EyraUI.Form.ValidationErrors

  prop(form, :form, required: true)
  prop(field, :atom, required: true)
  prop(label_text, :string, required: true)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, required: true)
  prop(change, :event)
  prop(read_only, :boolean, default: false)
  prop(reserve_error_space, :boolean, default: true)

  def render(assigns) do
    ~H"""
    <Label form={{@form}} field={{@field}} label_text={{@label_text}} label_color={{@label_color}} background={{@background}} />
    <Spacing value="2" />
    <slot />
    <Spacing value="2" />
    <ValidationErrors form={{@form}} field={{@field}} reserve_error_space={{@reserve_error_space}}/>
    """
  end
end
