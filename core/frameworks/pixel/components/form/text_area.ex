defmodule Frameworks.Pixel.Form.TextArea do
  @moduledoc false
  use Surface.Component
  alias Frameworks.Pixel.Form.Field
  import Frameworks.Pixel.FormHelpers

  import Phoenix.HTML
  import Phoenix.HTML.Form

  prop(field, :atom, required: true)
  prop(label_text, :string)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, default: :light)

  def render(assigns) do
    ~F"""
      <Context
        get={Surface.Components.Form, form: form}
      >
        <Field form={form} field={@field} label_text={@label_text} label_color={@label_color} background={@background} extra_space={false}>
          <textarea
            id={input_id(form, @field)}
            name={input_name(form, @field)}
            class="text-grey1 text-bodymedium font-body pl-3 pt-2 w-full h-64 border-2 focus:outline-none rounded"
            x-bind:class={"{ '#{focus_border_color(@background)}': focus === '#{@field}', '#{border_color(assigns, form)}': focus !== '#{@field}' }"}
            x-on:focus={"focus = '#{@field}'"}
            x-on:click.stop
            phx-focus="focus"
            phx-value-field={@field}
            phx-target={target(form)}
            phx-debounce="1000"
          >{html_escape(input_value(form, @field) || "")}</textarea>
        </Field>
      </Context>
    """
  end
end
