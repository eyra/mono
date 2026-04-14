defmodule Frameworks.Pixel.InlineBlock do
  @moduledoc """
  A self-contained content block with a border, used to visually
  distinguish a specific context from surrounding content.

  Renders a bordered container with a title and description on the left,
  an optional icon on the right, and optional button/content below.
  On small screens the icon sits next to the title only, with description
  below at full width.
  """
  use CoreWeb, :pixel

  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Button

  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:button, :map, default: nil)
  attr(:icon, :string, default: nil)

  slot(:inner_block)

  def inline_block(assigns) do
    ~H"""
    <div class="border-grey4 border-2 rounded p-6" data-testid="inline-block">
      <div class="flex flex-row items-start">
        <div class="flex-grow">
          <Text.title3><%= @title %></Text.title3>
          <div class="hidden sm:block">
            <Text.body><%= @description %></Text.body>
          </div>
        </div>
        <div :if={@icon} class="flex-shrink-0 ml-4">
          <img src={@icon} alt="" class="w-20 h-20" />
        </div>
      </div>
      <div class="sm:hidden">
        <Text.body><%= @description %></Text.body>
      </div>
      <.spacing value="S" />
      <%= if @button do %>
        <Button.dynamic_bar buttons={[@button]} />
      <% end %>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
