defmodule EyraUI.Form.Field do
  @moduledoc false
  use Surface.Component
  alias Surface.Components.Form.Label
  alias EyraUI.Form.{ValidationErrors, InputValue}
  alias EyraUI.Case.{Case, True, False}

  prop field, :atom, required: true
  prop label_text, :string, required: true
  prop change, :event
  prop read_only, :boolean, default: false

  def render(assigns) do
    ~H"""
    <div class="flex flex-col mb-8">
      <Label field={{@field}}
              opts={{class: "flex-wrap mt-0.5 text-title6 font-title6 mb-2"}} >
        {{@label_text}}
      </Label>
      <Case value={{@read_only}}>
        <True>
          <InputValue field={{@field}}/>
        </True>
        <False>
          <slot />
          <ValidationErrors field={{@field}} />
        </False>
      </Case>
    </div>
    """
  end
end
