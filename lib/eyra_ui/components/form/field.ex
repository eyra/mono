defmodule EyraUI.Form.Field do
  use Surface.Component
  alias Surface.Components.Form.Label
  alias EyraUI.Form.ValidationErrors

  prop field, :atom, required: true
  prop label_text, :string, required: true
  prop change, :event

  def render(assigns) do
    ~H"""
    <div class="flex flex-col mb-8">
      <Label field={{@field}}
              opts={{class: "flex-wrap mt-0.5 text-title6 font-title6 mb-2"}} >
        {{@label_text}}
      </Label>
      <slot />
      <ValidationErrors field={{@field}} />
    </div>
    """
  end
end
