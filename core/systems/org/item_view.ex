defmodule Systems.Org.ItemView do
  use CoreWeb, :html
  alias Frameworks.Pixel.Panel
  import Frameworks.Pixel.Tag

  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:tags, :list, default: [])
  attr(:title_color, :string, default: "text-grey1")
  attr(:description_color, :string, default: "text-grey1")
  attr(:event, :string, default: "handle_item_click")
  attr(:item, :string, required: true)
  attr(:target, :string, default: "")

  def item_view(assigns) do
    ~H"""
    <Panel.clickable
      size="w-full h-full"
      bg_color="bg-grey5"
      event={@event}
      item={@item}
      target={@target}
    >
      <:title>
        <div class={"text-title3 font-title3 #{@title_color}"}>
          <%= @title %>
        </div>
      </:title>
      <.spacing value="M" />
      <div class={"text-subhead font-subhead #{@description_color}"}>
        <span class="whitespace-pre-wrap"><%= @description %></span>
      </div>
      <.spacing value="M" />
      <div class="flex flex-row flex-wrap gap-x-4 gap-y-3 items-center">
        <%= for tag <- @tags do %>
          <.tag text={tag} />
        <% end %>
      </div>
    </Panel.clickable>
    """
  end
end
