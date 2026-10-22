defmodule CoreWeb.UI.Wrap do
  use CoreWeb, :ui

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
