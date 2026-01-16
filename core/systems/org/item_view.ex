defmodule Systems.Org.ItemView do
  use CoreWeb, :html

  import Frameworks.Pixel.ClickableCard
  import Frameworks.Pixel.Tag

  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:tags, :list, default: [])
  attr(:title_color, :string, default: "text-grey1")
  attr(:description_color, :string, default: "text-grey1")
  attr(:item, :any, required: true)
  attr(:left_actions, :list, default: [])
  attr(:right_actions, :list, default: [])

  def item_view(assigns) do
    ~H"""
    <.clickable_card
      id={@item}
      bg_color="grey5"
      left_actions={@left_actions}
      right_actions={@right_actions}
    >
      <:title>
        <div class={"text-title5 font-title5 lg:text-title3 lg:font-title3 #{@title_color}"}>
          <%= @title %>
        </div>
      </:title>

      <div class={"text-subhead font-subhead #{@description_color}"}>
        <span class="whitespace-pre-wrap"><%= @description %></span>
      </div>
      <.spacing value="M" />
      <div class="flex flex-row flex-wrap gap-x-4 gap-y-3 items-center">
        <%= for tag <- @tags do %>
          <.tag text={tag} />
        <% end %>
      </div>
    </.clickable_card>
    """
  end
end
