defmodule Frameworks.Pixel.Case.Case do
  @moduledoc """
  A line.
  """
  use Surface.Component

  slot(case_if)
  slot(case_else)

  prop(value, :boolean, required: true)

  def render(assigns) do
    ~F"""
    <div :if={@value && slot_assigned?(:case_if)}>
      <#slot {@case_if} />
    </div>
    <div :if={!@value && slot_assigned?(:case_else)}>
      <#slot {@case_else} />
    </div>
    """
  end
end
