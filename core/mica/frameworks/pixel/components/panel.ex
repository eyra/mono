defmodule Frameworks.Pixel.Panel do
  @moduledoc """
    Grouping information in a card-like fashion.
  """
  use CoreWeb, :pixel

  attr(:bg_color, :string, default: "bg-grey6")
  attr(:size, :string, default: "h-full")
  attr(:align, :string, default: "text-left")
  attr(:padding, :string, default: "p-6 lg:p-8")

  slot(:inner_block, required: true)
  slot(:title)

  def flat(assigns) do
    ~H"""
    <div class={"#{@bg_color} #{@size} rounded-md"}>
      <div class={"#{@padding} #{@align}"}>
        <%= render_slot(@title) %>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr(:bg_color, :string, default: "bg-grey6")
  attr(:size, :string, default: "h-full")
  attr(:align, :string, default: "text-left")
  attr(:padding, :string, default: "p-6 lg:p-8")

  attr(:event, :string, default: "handle_panel_click")
  attr(:item, :string, required: true)
  attr(:target, :any, default: false)

  slot(:title, required: true)
  slot(:inner_block, required: true)

  def clickable(assigns) do
    ~H"""
    <div
      phx-click={@event}
      phx-value-item={@item}
      phx-target={@target}
      class={"#{@bg_color} #{@size} rounded-md cursor-pointer"}
    >
      <div class={"#{@padding} #{@align}"}>
        <%= render_slot(@title) %>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:title_color, :string, default: "text-grey1")
  attr(:description_color, :string, default: "text-grey2")

  def usp(assigns) do
    ~H"""
    <.flat size="h-full">
      <:title>
        <div class={"text-title5 font-title5 lg:text-title4 lg:font-title4 mb-4 lg:mb-6 #{@title_color}"}>
          <%= @title %>
        </div>
      </:title>
      <div class={"text-bodysmall lg:text-bodymedium font-body #{@description_color}"}>
        <%= @description %>
      </div>
    </.flat>
    """
  end
end
