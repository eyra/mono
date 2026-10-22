defmodule Frameworks.Pixel.SidePanel do
  @moduledoc false
  use CoreWeb, :pixel

  attr(:id, :atom, required: true)
  attr(:parent, :atom, required: true)
  attr(:bg_color, :string, default: "bg-grey5")
  attr(:width, :string, default: "w-side-panel")
  slot(:inner_block, required: true)

  def side_panel(assigns) do
    ~H"""
    <div id={@id} data-parent={@parent} class={"#{@width} #{@bg_color}"} phx-hook="SidePanel">
      <div class={"panel #{@width} scrollbar-hidden overflow-y-scroll #{@bg_color}"}>
        <div class="mx-6 mb-6">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end
end
