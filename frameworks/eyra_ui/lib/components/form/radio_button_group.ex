defmodule EyraUI.Form.RadioButtonGroup do
  @moduledoc false
  use Surface.Component
  alias Surface.Components.Form.{Field, RadioButton}
  alias EyraUI.Form.ValidationErrors
  alias EyraUI.Text.BodyLarge
  alias EyraUI.Spacing

  prop(field, :atom, required: true)
  prop(items, :list, required: true)
  prop(checked, :string)
  prop(label_color, :css_class, default: "text-grey1")

  def render(assigns) do
    ~H"""
    <Context get={{Surface.Components.Form, form: form}} >
      <div class="flex flex-row mb-3">
        <Field name={{@field}}>
        <For each={{ item <- @items }} >
            <div class="flex flex-row items-center">
            <RadioButton value={{ item.id }} checked={{ item.id === @checked }} opts={{class: "flex-wrap border-2 h-6 w-6 border-solid focus:outline-none focus:border-primary"}} />
            <Spacing value="XS" direction="l" />
            <BodyLarge>
              {{ item.label }}
            </BodyLarge>
            </div>
          </For>
          <ValidationErrors form={{form}} field={{@field}} />
        </Field>
      </div>
    </Context>
    """
  end
end
