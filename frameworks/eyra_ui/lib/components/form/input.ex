defmodule EyraUI.Form.Input do
  @moduledoc false
  use Surface.Component
  alias EyraUI.Form.Field

  import EyraUI.FormHelpers

  import Phoenix.HTML.Form, only: [input_id: 2, input_name: 2, input_value: 2]

  prop(form, :form, required: true)
  prop(field, :atom, required: true)
  prop(type, :string, required: true)
  prop(label_text, :string)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, default: :light)

  def render(assigns) do
    ~H"""
      <Field form={{@form}} field={{@field}} label_text={{@label_text}} label_color={{@label_color}} background={{@background}}>
        <input
          type={{@type}}
          id={{ input_id(@form, @field) }}
          name={{ input_name(@form, @field) }}
          value={{ input_value(@form, @field) }}
          class="text-grey1 text-bodymedium font-body pl-3 w-full border-2 border-solid focus:outline-none rounded h-44px"
          x-bind:class="{ '{{focus_border_color(@background)}}': focus === '{{@field}}', '{{border_color(assigns, @form)}}': focus !== '{{@field}}' }"
          x-on:focus="focus = '{{ @field }}'"
          x-on:click.stop
          phx-focus="focus"
          phx-value-field={{ @field }}
        />
      </Field>
    """
  end
end
