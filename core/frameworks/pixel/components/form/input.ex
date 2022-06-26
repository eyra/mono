defmodule Frameworks.Pixel.Form.Input do
  @moduledoc false
  use Surface.Component
  alias Frameworks.Pixel.Form.Field

  import Frameworks.Pixel.FormHelpers

  import Phoenix.HTML.Form, only: [input_id: 2, input_name: 2, input_value: 2]

  prop(field, :atom, required: true)
  prop(type, :string, required: true)
  prop(placeholder, :string, default: "")
  prop(label_text, :string)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, default: :light)
  prop(disabled, :boolean, default: false)
  prop(reserve_error_space, :boolean, default: true)
  prop(debounce, :string, default: "1000")
  prop(value, :any, default: nil)
  slot(default)

  # Under some conditions a Frameworks.Pixel.Form.DateInput has its value reset to original value when using Phoenix.HTML.Form.input_value/2.
  # By inserting the value directly it always keeps the correct value.
  defp value(form, %{value: nil, field: field}), do: input_value(form, field)
  defp value(_form, %{value: value}), do: value

  def render(assigns) do
    ~F"""
    <Context get={Surface.Components.Form, form: form}>
      <#slot />
      <Field
        form={form}
        field={@field}
        label_text={@label_text}
        label_color={@label_color}
        background={@background}
        reserve_error_space={@reserve_error_space}
      >
        <input
          :if={@disabled}
          type={@type}
          id={input_id(form, @field)}
          name={input_name(form, @field)}
          value={value(form, assigns)}
          placeholder={@placeholder}
          class="text-grey3 bg-white placeholder-grey3 text-bodymedium font-body pl-3 w-full disabled:border-grey3 border-2 border-solid focus:outline-none rounded h-44px"
          disabled
        />
        <input
          :if={not @disabled}
          type={@type}
          id={input_id(form, @field)}
          name={input_name(form, @field)}
          value={value(form, assigns)}
          min="0"
          placeholder={@placeholder}
          class="text-grey1 text-bodymedium font-body pl-3 w-full border-2 border-solid focus:outline-none rounded h-44px"
          x-bind:class={"{ '#{focus_border_color(@background)}': focus === '#{@field}', '#{border_color(assigns, form)}': focus !== '#{@field}' }"}
          x-on:focus={"focus = '#{@field}'"}
          x-on:click.stop
          phx-focus="focus"
          phx-value-field={@field}
          phx-target={target(form)}
          phx-debounce={@debounce}
        />
      </Field>
    </Context>
    """
  end
end
