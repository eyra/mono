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
  prop(debounce, :string, default: "1000")

  data(form, :form, from_context: {Surface.Components.Form, :form})

  def render(%{form: form, field: field} = assigns) do
    field_id = String.to_atom(input_id(form, field))
    field_name = input_name(form, field)
    field_value = input_value(form, field) || ""
    error = field_error_message(assigns, form)
    error? = error != nil

    ~F"""
    <Field
      field={field_id}
      label_text={@label_text}
      label_color={@label_color}
      background={@background}
      error={error}
      extra_space={false}
    >
      <textarea
        id={field_id}
        name={field_name}
        class={"text-grey1 text-bodymedium font-body pl-3 pt-2 w-full h-64 border-2 focus:outline-none rounded #{get_border_color({false, error?, @background})}"}
        phx-target={target(form)}
        phx-debounce={@debounce}
      >{html_escape(field_value)}</textarea>
    </Field>
    """
  end
end
