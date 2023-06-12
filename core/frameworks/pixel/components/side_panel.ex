defmodule Frameworks.Pixel.SidePanel do
  @moduledoc false
  use CoreWeb, :html

  attr(:id, :atom, required: true)
  attr(:bg_color, :string, default: "bg-grey5")
  slot(:inner_block, required: true)

  def side_panel(assigns) do
    ~H"""
    <div id={@id} class={"relative top-0 right-0 w-side-panel #{@bg_color}"} phx-hook="SidePanel">
      <div class="panel w-side-panel overflow-y-scroll">
        <div class="mx-6 mb-6">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end
end
