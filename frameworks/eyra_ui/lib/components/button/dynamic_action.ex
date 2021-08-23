defmodule EyraUI.Button.DynamicAction do
  use EyraUI.Component
  alias EyraUI.Button.Action.{Click, Redirect, Send, Submit}

  slot(default, required: true)
  prop(vm, :map, required: true)

  defviewmodel(type: nil)

  def render(assigns) do
    ~H"""
      <div>
        <Click :if={{ type(@vm) === :click }} vm={{@vm}}>
          <slot />
        </Click>
        <Redirect :if={{ type(@vm) === :redirect }} vm={{@vm}}>
          <slot />
        </Redirect>
        <Send :if={{ type(@vm) === :send }} vm={{@vm}}>
          <slot />
        </Send>
        <Submit :if={{ type(@vm) === :submit }} vm={{@vm}}>
          <slot />
        </Submit>
      </div>
    """
  end
end
