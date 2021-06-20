defmodule EyraUI.Form.Form do
  @moduledoc false
  use Surface.Component
  alias Surface.Components.Form

  slot(default, required: true)

  prop(id, :string, required: true)
  prop(changeset, :any, required: true)
  prop(change_event, :any, required: true)
  prop(focus, :string, required: true)
  prop(target, :any)

  def render(assigns) do
    ~H"""
    <div
      x-data="{ focus: '{{@focus}}' }"
    >
      <Form for={{ @changeset }} change={{@change_event}} opts={{ id: @id, phx_target: @target }} >
        <slot />
      </Form>
    </div>
    """
  end
end
