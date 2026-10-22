defmodule Systems.Pool.ItemView do
  @moduledoc """
  The Pool Card displays information about a participant pool.
  """
  use CoreWeb, :html
  alias Frameworks.Pixel.Panel
  import Frameworks.Pixel.Tag

  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:tags, :list, default: [])
  attr(:title_color, :string, default: "text-grey1")
  attr(:description_color, :string, default: "text-grey1")
  attr(:event, :string, default: "handle_pool_click")
  attr(:item, :string, required: true)
  attr(:target, :any, default: false)

  attr(:left_actions, :list, default: [])
  attr(:right_actions, :list, default: [])

  def normal(assigns) do
    ~H"""
    <Panel.clickable
      size="w-full h-full"
      bg_color="bg-grey5"
      event={@event}
      target={@target}
      item={@item}
    >
      <:title>
        <div class={"text-title3 font-title3 #{@title_color}"}>
          <%= @title %>
        </div>
      </:title>
      <.spacing value="M" />
      <div class="flex flex-col gap-8">
        <div class={"text-subhead font-subhead #{@description_color}"}>
          <span class="whitespace-pre-wrap"><%= @description %></span>
        </div>

        <%= if Enum.count(@tags) > 0 do %>
          <div class="flex flex-row flex-wrap gap-x-4 gap-y-3 items-center">
            <%= for tag <- @tags do %>
              <.tag text={tag} />
            <% end %>
          </div>
        <% end %>

        <%= if Enum.count(@left_actions) > 0 or Enum.count(@right_actions) > 0 do %>
          <div class="flex flex-row gap-4 items-center">
            <%= for button <- @left_actions do %>
              <Button.dynamic {button} />
            <% end %>
            <div class="flex-grow" />
            <%= for button <- @right_actions do %>
              <Button.dynamic {button} />
            <% end %>
          </div>
        <% end %>
      </div>
    </Panel.clickable>
    """
  end
end
