defmodule Frameworks.Pixel.Button.DynamicAction do
  use Frameworks.Pixel.Component
  alias Frameworks.Pixel.Button.Action.{Click, Redirect, Send, Submit, Toggle, Href}

  slot(default, required: true)
  prop(vm, :map, required: true)

  defviewmodel(type: nil)

  def render(assigns) do
    ~H"""
      <div class="h-full">
        <div class="flex flex-col h-full justify-center">
          <div class="flex-wrap">
            <Toggle :if={{ type(@vm) == :toggle }} vm={{@vm}}>
              <slot />
            </Toggle>
            <Click :if={{ type(@vm) == :click }} vm={{@vm}}>
              <slot />
            </Click>
            <Redirect :if={{ type(@vm) == :redirect }} vm={{@vm}}>
              <slot />
            </Redirect>
            <Send :if={{ type(@vm) == :send }} vm={{@vm}}>
              <slot />
            </Send>
            <Submit :if={{ type(@vm) == :submit }} vm={{@vm}}>
              <slot />
            </Submit>
            <Href :if={{ type(@vm) == :href }} vm={{@vm}}>
              <slot />
            </Href>
          </div>
        </div>
      </div>
    """
  end
end
