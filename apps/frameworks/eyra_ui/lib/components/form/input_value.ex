defmodule EyraUI.Form.InputValue do
  @moduledoc false
  use Surface.Component
  alias Surface.Components.Form.Input.InputContext
  alias EyraUI.Text.BodyMedium
  import Phoenix.HTML.Form

  prop(field, :atom)
  prop(form, :form)

  def render(assigns) do
    ~H"""
    <InputContext assigns={{ assigns }} :let={{ form: form, field: field }}>
      <BodyMedium>{{input_value(form,field)}}</BodyMedium>
    </InputContext>
    """
  end
end
