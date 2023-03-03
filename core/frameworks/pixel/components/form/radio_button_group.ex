defmodule Frameworks.Pixel.Form.RadioButtonGroup do
  @moduledoc false
  use Surface.Component
  import Frameworks.Pixel.FormHelpers
  import Phoenix.HTML.Form, only: [input_id: 2]

  alias Surface.Components.Form.RadioButton
  alias Frameworks.Pixel.Text.BodyLarge
  alias Frameworks.Pixel.Spacing
  alias Frameworks.Pixel.Form.Field

  prop(field, :atom, required: true)
  prop(items, :list, required: true)
  prop(checked, :string)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, default: :light)

  data(form, :form, from_context: {Surface.Components.Form, :form})

  def render(%{form: form, field: field} = assigns) do
    error = field_error_message(assigns, form)
    field_id = String.to_atom(input_id(form, field))

    ~F"""
    <div class="flex flex-row mb-3">
      <Field field={field_id} error={error} background={@background}>
        {#for item <- @items}
          <div class="flex flex-row items-center">
            <RadioButton
              value={item.id}
              checked={item.id === @checked}
              opts={class: "flex-wrap border-2 h-6 w-6 border-solid focus:outline-none focus:border-primary"}
            />
            <Spacing value="XS" direction="l" />
            <BodyLarge>
              {item.label}
            </BodyLarge>
          </div>
        {/for}
      </Field>
    </div>
    """
  end
end
