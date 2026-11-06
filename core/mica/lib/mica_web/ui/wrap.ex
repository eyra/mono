defmodule MicaWeb.UI.Wrap do
  use MicaWeb, :ui

  slot(:inner_block, required: true)

  def wrap(assigns) do
    ~H"""
    <div class="flex flex-row">
      <div class="flex-wrap">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
