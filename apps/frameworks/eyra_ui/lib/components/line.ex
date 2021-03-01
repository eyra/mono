defmodule EyraUI.Line do
  @moduledoc """
  A line.
  """
  use Surface.Component

  def render(assigns) do
    ~H"""
    <div class="mb-7 bg-grey4 h-px"></div>
    """
  end
end
