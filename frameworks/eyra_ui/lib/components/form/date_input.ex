defmodule EyraUI.Form.DateInput do
  @moduledoc false
  use Surface.Component
  alias EyraUI.Form.Input

  prop(field, :atom, required: true)
  prop(label_text, :string)
  prop(label_color, :css_class, default: "text-grey1")
  prop(background, :atom, default: :light)
  prop(disabled, :boolean, default: false)

  def render(assigns) do
    ~H"""
      <Input field={{@field}} label_text={{@label_text}} label_color={{@label_color}} background={{@background}} type="date" disabled={{ @disabled }} debounce={{ nil }}/>
    """
  end
end
