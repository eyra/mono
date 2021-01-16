defmodule EyraUI.Form.Checkbox do
  use Surface.Component
  alias Surface.Components.Form.Checkbox
  alias EyraUI.Form.Field

  prop field, :atom, required: true
  prop label_text, :string

  def render(assigns) do
    ~H"""
    <Field field={{@field}} label_text={{@label_text}}>
      <Checkbox field={{@field}} />
    </Field>
    """
  end
end
