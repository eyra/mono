defmodule Frameworks.Pixel.Form.Form do
  @moduledoc false
  use Surface.Component
  alias Surface.Components.Form

  slot(default, required: true)

  prop(id, :string, required: true)
  prop(changeset, :any, required: true)
  prop(change_event, :any)
  prop(submit, :any)
  prop(focus, :string, required: true)
  prop(target, :any, default: "")

  def render(assigns) do
    ~F"""
    <div
      x-data={"{ focus: '#{@focus}' }"}
    >
      <Context put={target: @target}>
        <Form for={@changeset} submit={@submit} change={@change_event} opts={id: @id, phx_target: @target} >
          <#slot />
        </Form>
      </Context>
    </div>
    """
  end
end
