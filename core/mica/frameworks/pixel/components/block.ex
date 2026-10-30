defmodule Frameworks.Pixel.Block do
  @moduledoc """
  The Unique Selling Point Card highlights a reason for taking an action.
  """
  use MicaWeb, :pixel

  slot(:inner_block, required: true)

  def block(assigns) do
    ~H"""
    <div class="flex-wrap">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
