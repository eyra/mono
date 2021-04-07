defmodule EyraUI.Form.InputValue do
  @moduledoc false
  use Surface.Component
  alias Surface.Components.Form.Input.InputContext
  alias EyraUI.Text.BodyMedium
  import Phoenix.HTML.Form

  prop(field, :atom)
  prop(form, :form)
  prop(text_color, :css_class, default: "text-grey2")

  def render(assigns) do
    ~H"""
    <InputContext assigns={{ assigns }} :let={{ form: form, field: field }}>
      <BodyMedium color={{@text_color}} >{{input_value(form,field)}}</BodyMedium>
    </InputContext>
    """
  end
end
