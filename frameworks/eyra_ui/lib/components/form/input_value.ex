defmodule EyraUI.Form.InputValue do
  @moduledoc false
  use Surface.Component
  alias EyraUI.Text.BodyMedium
  import Phoenix.HTML.Form

  prop(form, :form, required: true)
  prop(field, :atom, required: true)
  prop(text_color, :css_class, default: "text-grey2")

  def render(assigns) do
    ~H"""
    <BodyMedium color={{@text_color}} >
      {{ input_value(@form, @field) }}
    </BodyMedium>
    """
  end
end
