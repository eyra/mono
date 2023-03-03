defmodule Frameworks.Pixel.Form.Inputs do
  @moduledoc false
  use Surface.Component

  prop(field, :atom)
  prop(target, :any, default: "")

  slot(default, required: true)

  data(form, :form, from_context: {Surface.Components.Form, :form})

  def render(assigns) do
    ~F"""
    <div :for={subform <- Phoenix.HTML.Form.inputs_for(@form, @field, phx_target: @target)}>
      <Context put={Surface.Components.Form, form: subform}>
        <#slot />
      </Context>
    </div>
    """
  end
end
