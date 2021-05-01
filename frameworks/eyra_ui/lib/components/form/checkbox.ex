defmodule EyraUI.Form.Checkbox do
  @moduledoc false
  use Surface.Component
  alias Surface.Components.Form.{Checkbox, Label}
  alias EyraUI.Form.ValidationErrors

  prop(field, :atom, required: true)
  prop(label_text, :string)
  prop(label_color, :css_class, default: "text-grey1")

  def render(assigns) do
    ~H"""
    <Context get={{Surface.Components.Form, form: form}} >
      <div class="flex flex-row mb-3">
        <Checkbox field={{@field}} opts={{class: "flex-wrap border-2 h-6 w-6 border-solid focus:outline-none focus:border-primary rounded-lg"}} />
        <Label field={{@field}} opts={{class: "flex-wrap ml-3 mr-3 h-6 mt-1.5 font-label text-label #{@label_color}"}} >
          {{@label_text}}
        </Label>
        <ValidationErrors form={{form}} field={{@field}}/>
      </div>
    </Context>
    """
  end
end
