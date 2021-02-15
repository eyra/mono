defmodule EyraUI.Case.Case do
  @moduledoc """
  A line.
  """
  use Surface.Component

  slot case_if
  slot case_else

  prop value, :boolean, required: true

  def render(assigns) do
    ~H"""
    <div :if={{@value && slot_assigned?(:case_if) }}>
      <slot name="case_if"/>
    </div>
    <div :if={{ !@value && slot_assigned?(:case_else) }}>
      <slot name="case_else"/>
    </div>
    """
  end
end
