defmodule EyraUI.Form.NumberInput do
  @moduledoc false
  use Surface.Component
  alias Surface.Components.Form.NumberInput
  alias EyraUI.Form.Field

  prop field, :atom, required: true
  prop label_text, :string
  prop read_only, :boolean, default: false

  def render(assigns) do
    ~H"""
    <Field field={{@field}} label_text={{@label_text}} read_only={{@read_only}}>
      <NumberInput field={{@field}} opts={{class: "text-grey1 text-bodymedium font-body pl-3 w-full border-2 border-solid border-grey3 focus:outline-none focus:border-primary rounded h-44px"}} />
    </Field>
    """
  end
end
