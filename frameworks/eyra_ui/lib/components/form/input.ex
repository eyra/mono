defmodule EyraUI.Form.Input do
  @moduledoc false
  use Surface.Component
  alias EyraUI.Form.Field

  import EyraUI.FormHelpers

  import Phoenix.HTML.Form, only: [input_id: 2, input_name: 2, input_value: 2]

  prop(field, :atom, required: true)
  prop(type, :string, required: true)
  prop(placeholder, :string, default: "")
  prop(label_text, :string)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, default: :light)
  prop(disabled, :boolean, default: false)
  prop(debounce, :string, default: "1000")
  slot(default)

  def render(assigns) do
    ~H"""
      <Context
        get={{Surface.Components.Form, form: form}}
        get={{target: target}}
      >
        <slot />
        <Field form={{form}} field={{@field}} label_text={{@label_text}} label_color={{@label_color}} background={{@background}}>
          <input :if={{ @disabled }}
            type={{@type}}
            id={{ input_id(form, @field) }}
            name={{ input_name(form, @field) }}
            value={{ input_value(form, @field) }}
            placeholder={{@placeholder}}
            class="text-grey3 bg-white placeholder-grey3 text-bodymedium font-body pl-3 w-full disabled:border-grey3 border-2 border-solid focus:outline-none rounded h-44px"
            disabled
          />
          <input :if={{ not @disabled }}
            type={{@type}}
            id={{ input_id(form, @field) }}
            name={{ input_name(form, @field) }}
            value={{ input_value(form, @field) }}
            placeholder={{@placeholder}}
            class="text-grey1 text-bodymedium font-body pl-3 w-full border-2 border-solid focus:outline-none rounded h-44px"
            x-bind:class="{ '{{focus_border_color(@background)}}': focus === '{{@field}}', '{{border_color(assigns, form)}}': focus !== '{{@field}}' }"
            x-on:focus="focus = '{{ @field }}'"
            x-on:click.stop
            phx-focus="focus"
            phx-value-field={{ @field }}
            phx-target={{ target }}
            phx-debounce={{@debounce}}
          />
        </Field>
      </Context>
    """
  end
end
