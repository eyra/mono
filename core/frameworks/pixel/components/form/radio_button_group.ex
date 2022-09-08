defmodule Frameworks.Pixel.Form.RadioButtonGroup do
  @moduledoc false
  use Surface.Component
  alias Surface.Components.Form.{Field, RadioButton}
  alias Frameworks.Pixel.Form.ValidationErrors
  alias Frameworks.Pixel.Text.BodyLarge
  alias Frameworks.Pixel.Spacing

  prop(field, :atom, required: true)
  prop(items, :list, required: true)
  prop(checked, :string)
  prop(label_color, :css_class, default: "text-grey1")

  data(form, :form, from_context: {Surface.Components.Form, :form})

  def render(assigns) do
    ~F"""
    <div class="flex flex-row mb-3">
      <Field name={@field}>
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
        <ValidationErrors form={@form} field={@field} />
      </Field>
    </div>
    """
  end
end
