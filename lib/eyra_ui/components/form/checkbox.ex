defmodule EyraUI.Form.Checkbox do
  use Surface.Component
  alias Surface.Components.Form.{Checkbox, Label}
  alias EyraUI.Form.ValidationErrors

  prop field, :atom, required: true
  prop label_text, :string

  def render(assigns) do
    ~H"""
    <div class="flex flex-row mb-3">
      <Checkbox field={{@field}} opts={{class: "flex-wrap border-2 h-6 w-6 border-solid focus:outline-none focus:border-primary rounded-lg"}} />
      <Label field={{@field}} opts={{class: "flex-wrap ml-3 mr-3 h-6 mt-1.5 font-label text-label"}} >
        {{@label_text}}
      </Label>
      <ValidationErrors field={{@field}} />
      </div>
    """
  end
end
