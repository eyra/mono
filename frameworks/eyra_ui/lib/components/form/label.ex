defmodule EyraUI.Form.Label do
  @moduledoc false
  use Surface.Component

  import EyraUI.FormHelpers

  prop(form, :form, required: true)
  prop(field, :atom, required: true)
  prop(label_text, :string, required: true)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, default: :light)

  def render(assigns) do
    ~H"""
    <div class="mt-0.5 text-title6 font-title6 leading-snug"
        x-bind:class="{'{{focus_label_color(@background)}}': focus === '{{@field}}', '{{label_color(assigns, @form, @label_color)}}': focus !== '{{@field}}' }"
    >
      {{@label_text}}
    </div>
    """
  end
end
