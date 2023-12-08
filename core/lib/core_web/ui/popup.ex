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

  attr(:popup, :map, default: nil)

  def takeover(assigns) do
    ~H"""
    <div class={"fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-30 #{if @popup do "block" else "hidden" end}"}>
      <div class="flex flex-row items-center justify-center w-full h-full">
        <%= if @popup do %>
          <div class="w-3/5 h-4/5 overflow-y-scroll">
            <.live_component id={:page_popup} module={@popup.module} {@popup.params} />
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
