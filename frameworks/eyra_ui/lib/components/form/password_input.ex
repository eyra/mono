defmodule EyraUI.Form.PasswordInput do
  @moduledoc false
  use Surface.Component
  alias EyraUI.Form.Input

  prop(field, :atom, required: true)
  prop(label_text, :string)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, default: :light)

  def render(assigns) do
    ~H"""
    <Context get={{Surface.Components.Form, form: form}} >
      <Input form={{form}} field={{@field}} label_text={{@label_text}} label_color={{@label_color}} background={{@background}} type="password" />
    </Context>
    """
  end
end
