defmodule CoreWeb.UI.Popup do
  use CoreWeb, :html

  slot(:inner_block, default: nil)

  def popup(assigns) do
    ~H"""
    <div class={"fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-30 #{if @inner_block do "block" else "hidden" end}"}>
      <div class="flex flex-row items-center justify-center w-full h-full">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
